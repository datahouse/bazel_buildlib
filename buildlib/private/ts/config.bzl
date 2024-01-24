"""tsconfig rules"""

load("@aspect_bazel_lib//lib:paths.bzl", "relative_file")
load("@aspect_bazel_lib//lib:write_source_files.bzl", "write_source_file")
load("@aspect_rules_ts//ts:defs.bzl", "TsConfigInfo", "ts_config")
load("@bazel_skylib//lib:paths.bzl", "paths")
load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")
load(":providers.bzl", "TsLibraryInfo")

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

        if file.extension == "json":
            # Include all json files explicitly.
            #
            # An alternative would be to adjust the default wildcard matches, but that
            # would mean we need to explicitly exclude things like tsconfig.json.
            #
            # Note that we even need to add generated JSON files: when running
            # under rules_js/ts, source files (and the tsconfig.json itself!)
            # are first copied to the bindir. So even generated json files will
            # be under the normal relative path.
            include.append(relative_file(file.short_path, ctx.build_file_path))

    return include

def _tsconfig_references(ctx):
    ts_library_deps = [
        dep
        for dep in ctx.attr.deps
        if TsLibraryInfo in dep
    ]

    if not ctx.attr.uses_dom:
        dom_deps = [
            "- {}\n".format(dep.label)
            for dep in ts_library_deps
            if dep[TsLibraryInfo].uses_dom
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
    # See the "evil bazel hackery" comment in _write_to_src for why this is not
    # predeclared in the attrs.
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

    return DefaultInfo(files = depset([out]))

_gen_tsconfig = rule(
    attrs = {
        "deps": attr.label_list(),
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

def _gen_tsconfig_base_impl(ctx):
    # See the "evil bazel hackery" comment in _write_to_src for why this is not
    # predeclared in the attrs.
    out = ctx.actions.declare_file("tsconfig-base.json")

    cfg = {
        "compilerOptions": {
            "composite": True,
            "emitDecoratorMetadata": True,
            "esModuleInterop": True,
            "experimentalDecorators": True,
            "forceConsistentCasingInFileNames": True,
            "isolatedModules": True,
            "jsx": "react-jsx",
            "lib": ["es2018"],
            "module": ctx.attr._module_setting[BuildSettingInfo].value,
            "moduleResolution": "node",
            "outDir": "dist",
            "resolveJsonModule": True,
            "rootDir": ".",
            "rootDirs": [".", "bazel-bin"],
            "skipLibCheck": True,
            "sourceMap": True,
            "strict": True,
            "target": "es2018",
        },
    }

    ctx.actions.write(
        content = json.encode(cfg),
        output = out,
    )

    return DefaultInfo(files = depset([out]))

_gen_tsconfig_base = rule(
    attrs = {
        "_module_setting": attr.label(
            default = Label("//private/ts:module"),
            providers = [BuildSettingInfo],
        ),
    },
    implementation = _gen_tsconfig_base_impl,
)

def _write_to_src(name, testonly = None):
    """Macro to format and write tsconfig to source.

    - Assumes the presence of a target called name + ".gen" providing the relevant file.
    - Writes to name + ".json"

    This involves some evil bazel hackery:
    We want tsconfig.json (or tsconfig-base.json) to be generated but also
    write it to the source folder (so the IDE tools can be happy).

    To achieve this, we do not declare tsconfig.json as a predeclared output
    of _gen_tsconfig / _gen_tsconfig_base. As such, it will not receive a label
    (and the label `:tsconfig.json` / `:tsconfig-base.json` will always refer to
    the source file).
    """

    # Expand prettier label to resolve repository.
    # We need a string representation in the `cmd` below.
    prettier = Label("//private:prettier")

    # Use a genrule instead of js_run_binary because we need redirection:
    # Prettier refuses to format symlinks (starting 3.x), so we pipe the file
    # we want to format (but js_run_binary doesn't support stdin piping).
    native.genrule(
        name = name + ".fmt",
        cmd = "BAZEL_BINDIR=. $(location %s) --stdin-filepath $< < $< > $@" % prettier,
        testonly = testonly,
        srcs = [name + ".gen"],
        outs = [name + ".fmt.json"],
        tools = [prettier],
    )

    write_source_file(
        name = name + ".write",
        testonly = testonly,
        in_file = name + ".fmt",
        out_file = name + ".json",
    )

def tsconfig(name, srcs, deps, uses_dom, testonly = None):
    """tsconfig.json generation for a single ts_library (buildlib internal).

    - Will implicitly depend on `//:tsconfig-base`.
    - Will declare tsconfig.json (in bazel-bin).

    Args:
      name: name of rule (must be tsconfig)
      srcs: source files.
      deps: dependencies.
      uses_dom: Whether the DOM library should be enabled.
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
        testonly = testonly,
    )

    ts_config(
        name = "tsconfig",
        src = ":tsconfig.gen",
        deps = ["//:tsconfig-base"],
        testonly = testonly,
    )

    _write_to_src(
        name = "tsconfig",
        testonly = testonly,
    )

def tsconfig_base(name, visibility = None):
    """Base tsconfig for repository root.

    - must be in the root package
    - name must be tsconfig-base

    Example: See [`ts_setup`](#ts_setup)

    Args:
      name: Name of the rule (must be "tsconfig-base").
      visibility: Visibility of the tsconfig rule.
    """

    if name != "tsconfig-base":
        fail("name must be tsconfig-base, got %s" % name)

    if native.package_name() != "":
        fail("tsconfig-base must be in the root package")

    _gen_tsconfig_base(
        name = "tsconfig-base.gen",
    )

    ts_config(
        name = "tsconfig-base",
        src = ":tsconfig-base.gen",
        visibility = visibility,
    )

    _write_to_src(
        name = "tsconfig-base",
    )
