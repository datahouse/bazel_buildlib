"""tsconfig rules"""

load("@aspect_bazel_lib//lib:paths.bzl", "relative_file")
load("@aspect_bazel_lib//lib:write_source_files.bzl", "write_source_file")
load("@aspect_rules_ts//ts:defs.bzl", "TsConfigInfo", "ts_config")
load("@bazel_skylib//lib:paths.bzl", "paths")
load("//private:prettier_format.bzl", "prettier_format")

_GenTsConfigInfo = provider(
    doc = """Provider for gen_tsconfig (buidlib internal).

    Serves primarily as a marker, but also forwards info.
    """,
    fields = {
        "uses_dom": "Whether the tsconfig enables the DOM.",
    },
)

_TsLibraryInfo = provider(
    doc = """Provider for buildlib ts_library targets (buildlib internal).

    The provider gets attached to ts_project targets created by buildlib via
    _ts_library_info_aspect.
    """,
    fields = {
        "uses_dom": "Whether the library uses the DOM.",
    },
)

def _ts_library_info_aspect_impl(_target, ctx):
    if hasattr(ctx.rule.attr, "src") and _GenTsConfigInfo in ctx.rule.attr.src:
        # This is a ts_config target which depends on a gen_tsconfig target.
        # Therefore, the ts_config target created by buildlib --> propagate info.
        info = ctx.rule.attr.src[_GenTsConfigInfo]
        return [
            _TsLibraryInfo(uses_dom = info.uses_dom),
        ]

    if hasattr(ctx.rule.attr, "tsconfig") and _TsLibraryInfo in ctx.rule.attr.tsconfig:
        # This is a ts_project target which depends on a ts_config target created by bulidlib.
        # Therefore, the ts_project target was created by buildlib --> propagate info.
        return [ctx.rule.attr.tsconfig[_TsLibraryInfo]]

    # If we get here, our target is not created by buildlib --> do not return info.
    return []

_ts_library_info_aspect = aspect(
    implementation = _ts_library_info_aspect_impl,
    attr_aspects = ["deps", "tsconfig"],
)

def _tsconfig_includes(ctx):
    project_dir = paths.dirname(ctx.build_file_path)
    workspace_rel_path = paths.join(*[".." for _ in project_dir.split("/")])

    # Pattern for the bazel-bin dir. We add this so IDEs can find generated
    # sources. For the resolution to work correctly, `bazel-bin` also needs to
    # be added to `rootDirs` (so we can include `./bazel-bin/a/b` as `./a/b`).
    #
    # Note that the use of bazel-bin is not 100% clean: Bazel keeps multiple bin
    # dirs for different configs. bazel-bin just points to the last written one.
    # However, since all of this is only for IDE integration, this is good enough.
    bin_rel_pattern = paths.join(workspace_rel_path, "bazel-bin")

    include = ["**/*"]  # sources in the project directory itself.

    for file in ctx.files.srcs:
        if not file.is_source:
            # Generated file, add it explicitly (do *not* use a pattern, many
            # other things are in the generated directory we shouldn't include).
            include.append(paths.join(bin_rel_pattern, file.short_path))

    return include

def _tsconfig_references(ctx):
    ts_library_deps = [
        dep
        for dep in ctx.attr.deps
        if _TsLibraryInfo in dep
    ]

    if not ctx.attr.uses_dom:
        dom_deps = [
            "- {}\n".format(dep.label)
            for dep in ts_library_deps
            if dep[_TsLibraryInfo].uses_dom
        ]

        if dom_deps:
            fail("{} has deps requiring the DOM but doesn't set uses_dom = True.\n".format(ctx.label) +
                 "The following dependencies depend on the dom:\n{}".format("".join(dom_deps)) +
                 "To fix this you need to do either of the following\n" +
                 "- Add uses_dom = True (if the target is intended for the browser)\n" +
                 "- Remove the offending libraries\n" +
                 "- Remove uses_dom from the offending libraries (if they don't use the DOM)\n")

    references = [
        {"path": relative_file(dep.label.package, ctx.build_file_path)}
        for dep in ts_library_deps
    ]

    return references

def _gen_tsconfig_impl(ctx):
    # See [evil-bazel-hackery] for why this is not predeclared in the attrs.
    out = ctx.actions.declare_file("tsconfig.json")

    cfg = {
        "extends": relative_file(ctx.file.extends.short_path, ctx.build_file_path),
        "include": _tsconfig_includes(ctx),
        "references": _tsconfig_references(ctx),
    }

    if ctx.attr.uses_dom:
        cfg["compilerOptions"] = {"lib": ["dom", "dom.iterable", "es2018"]}

    ctx.actions.write(
        content = json.encode(cfg),
        output = out,
    )

    return [
        DefaultInfo(files = depset([out])),
        _GenTsConfigInfo(uses_dom = ctx.attr.uses_dom),
    ]

_gen_tsconfig = rule(
    attrs = {
        "deps": attr.label_list(
            aspects = [_ts_library_info_aspect],
        ),
        "extends": attr.label(
            allow_single_file = True,
            providers = [TsConfigInfo],
        ),
        "srcs": attr.label_list(
            allow_files = True,
        ),
        "uses_dom": attr.bool(),
    },
    implementation = _gen_tsconfig_impl,
)

def tsconfig(name, srcs, deps, uses_dom, tags = [], testonly = None):
    """tsconfig.json generation for a single ts_library (buildlib internal).

    - Will implicitly depend on `//:tsconfig-base`.
    - Will declare tsconfig.json (in bazel-bin).

    Args:
      name: name of rule (must be tsconfig)
      srcs: source files.
      deps: dependencies.
      uses_dom: Whether the DOM library should be enabled.
      tags: tags, propagated to all targets.
      testonly: testonly flag.
    """

    if name != "tsconfig":
        fail("name must be tsconfig. got '%s'" % name)

    _gen_tsconfig(
        name = "tsconfig.gen",
        srcs = srcs,
        deps = deps,
        uses_dom = uses_dom,
        extends = "//:tsconfig-base",
        tags = tags,
        testonly = testonly,
    )

    ts_config(
        name = "tsconfig",
        src = ":tsconfig.gen",
        deps = ["//:tsconfig-base"],
        tags = tags,
        testonly = testonly,
    )

    prettier_format(
        name = "tsconfig.format",
        src = "tsconfig.gen",
        out = "tsconfig.fmt.json",
        tags = tags,
        testonly = testonly,
    )

    write_source_file(
        name = "tsconfig.write",
        in_file = "tsconfig.fmt.json",
        out_file = "tsconfig.json",
        tags = tags,
        testonly = testonly,
    )

# [evil-bazel-hackery]
# We want tsconfig.json (or tsconfig-base.json) to be generated but also
# write it to the source folder (so the IDE tools can be happy).
#
# To achieve this, we do not declare tsconfig.json as a predeclared output
# of _gen_tsconfig / _gen_tsconfig_base. As such, it will not receive a label
# (and the label `:tsconfig.json` / `:tsconfig-base.json` will always refer to
# the source file).
