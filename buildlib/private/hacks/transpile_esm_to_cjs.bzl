"""Hacky rule to transpile ESM modules to CJS modules."""

load("@aspect_bazel_lib//lib:paths.bzl", "relative_file")
load("@aspect_rules_js//js:libs.bzl", "js_lib_helpers")
load("@aspect_rules_js//js:providers.bzl", "JsInfo", "js_info")
load("@bazel_skylib//lib:paths.bzl", "paths")

_TranspileInfo = provider(
    doc = """Internal provider for replacements""",
    fields = {
        "package_name": "Name of the transpiled package",
        "virtual_store": "Virtual store directory of the transpiled package",
    },
)

def _transpile(ctx, input, outdir, replacements):
    args = [
        "--outdir",
        outdir.path,
        "--indir",
        input.path,
    ]

    for src, trg in replacements.items():
        args.extend(["--replace", "{}={}".format(src, trg)])

    ctx.actions.run(
        executable = ctx.executable._transpiler,
        arguments = args,
        inputs = [input],
        outputs = [outdir],
        env = {
            "BAZEL_BINDIR": ".",
        },
    )

def _extract_package_name(label):
    if not label.name.startswith("node_modules/"):
        fail("name of transpile_node_module must start with node_modules/")

    return label.name.removeprefix("node_modules/")

def _extract_store(target):
    packages = target[JsInfo].npm_linked_packages.to_list()

    if len(packages) != 1:
        fail("expected exactly one package, got %s" % packages)

    return packages[0].store_info

def _trg_store_path(package_name):
    return paths.join("node_modules", ".dh_buildlib", package_name, "node_modules", package_name)

def _rel_symlink(ctx, name, trg):
    trg_link = ctx.actions.declare_symlink(name)
    ctx.actions.symlink(output = trg_link, target_path = relative_file(trg.short_path, name))
    return trg_link

def _store_root(vdir, package_name):
    """Determines the virtual store root based on the virtual directory and the package name.

    Admittedly somewhat of a hack. Example:

    Input:
      vdir: node_modules/.aspect_rules_js/graphql-upload@16.0.2_1146737453/node_modules/graphql-upload
      package_name: graphql-upload

    Ouput:
      node_modules/.aspect_rules_js/graphql-upload@16.0.2_1146737453
    """

    vdir_path = vdir.short_path
    suffix = paths.join("node_modules", package_name)

    if not vdir_path.endswith(suffix):
        fail("expected {} to end in {}".format(vdir, suffix))

    return vdir_path.removesuffix(suffix)

def _store_rel_path(store_root, file):
    if not file.short_path.startswith(store_root):
        return None

    return file.short_path.removeprefix(store_root)

def _pkg_name_from_rel_path(path):
    if not path.startswith("node_modules/"):
        fail("dependency {} is not in node_modules".format(path))

    return path.removeprefix("node_modules/")

def _link_src_dependencies(ctx, src_store_root, trg_store_root, src_target, ignore_pkgs):
    links = []

    for dep in src_target[JsInfo].transitive_npm_linked_package_files.to_list():
        rel_path = _store_rel_path(src_store_root, dep)

        if rel_path == None:
            # Not a direct dependency of the src package we're transpiling.
            # Yes, path based determination of this is a bit of a hack.
            continue

        # Determine the package name of the dependency.
        dep_pkg_name = _pkg_name_from_rel_path(rel_path)

        if dep_pkg_name in ignore_pkgs:
            continue

        # Link the package to the target virtual store.
        link = _rel_symlink(ctx, paths.join(trg_store_root, "node_modules", dep_pkg_name), dep)
        links.append(link)

    return links

def _js_info(output_depset, deps):
    npm_linked_packages = js_lib_helpers.gather_npm_linked_packages([], deps)

    return js_info(
        declarations = output_depset,
        npm_linked_package_files = npm_linked_packages.direct_files,
        npm_linked_packages = npm_linked_packages.direct,
        npm_package_store_deps = js_lib_helpers.gather_npm_package_store_deps(deps),
        sources = output_depset,
        transitive_declarations = js_lib_helpers.gather_transitive_declarations(output_depset, deps),
        transitive_npm_linked_package_files = npm_linked_packages.transitive_files,
        transitive_npm_linked_packages = npm_linked_packages.transitive,
        transitive_sources = js_lib_helpers.gather_transitive_sources(output_depset, deps),
    )

def _transpile_esm_to_cjs_impl(ctx):
    # Information about the source package (the one we are transpiling from).
    src_store = _extract_store(ctx.attr.node_module)
    src_store_vdir = src_store.virtual_store_directory
    src_store_root = _store_root(src_store_vdir, src_store.package)

    # Information about the target package (the one we are transpiling to).
    trg_package_name = _extract_package_name(ctx.label)
    trg_store_vdir = ctx.actions.declare_directory(_trg_store_path(trg_package_name))
    trg_store_root = _store_root(trg_store_vdir, trg_package_name)

    outputs = [trg_store_vdir]

    _transpile(
        ctx,
        src_store_vdir,
        trg_store_vdir,
        replacements = {
            name: replacement[_TranspileInfo].package_name
            for replacement, name in ctx.attr.replacements.items()
        },
    )

    # Link from nice name to virtual store
    outputs.append(_rel_symlink(ctx, ctx.label.name, trg_store_vdir))

    # Link to ordinary dependencies
    outputs.extend(_link_src_dependencies(
        ctx,
        src_store_root,
        trg_store_root,
        src_target = ctx.attr.node_module,
        ignore_pkgs = [src_store.package] + ctx.attr.replacements.values(),
    ))

    # Replaced dependencies.
    for replacement in ctx.attr.replacements:
        info = replacement[_TranspileInfo]
        path = paths.join(trg_store_root, "node_modules", info.package_name)
        outputs.append(_rel_symlink(ctx, path, info.virtual_store))

    # Calculate output
    output_depset = depset(outputs)
    deps = [ctx.attr.node_module] + ctx.attr.replacements.keys()

    runfiles = ctx.runfiles(transitive_files = output_depset).merge_all([d.default_runfiles for d in deps])

    return [
        _TranspileInfo(
            package_name = trg_package_name,
            virtual_store = trg_store_vdir,
        ),
        DefaultInfo(
            files = output_depset,
            runfiles = runfiles,
        ),
        _js_info(output_depset, deps),
    ]

transpile_esm_to_cjs = rule(
    doc = """Rule to transpile a ESM only npm package to CJS.

    Attention: This rule does the bare minimum we need for packages used in example.
    If you intend to use it in your project (after thinking twice, of course),
    make sure you validate that it actually works for your use case.

    Example: [`@examples//:node_modules/graphql-upload-cjs`](../../examples/BUILD.bazel#:~:text=name%20%3D%20%22node_modules/graphql%2Dupload%2Dcjs%22%2C)
    """,
    implementation = _transpile_esm_to_cjs_impl,
    attrs = {
        "node_module": attr.label(
            doc = "npm package to transpile (should be in //:node_modules/*)",
            providers = [JsInfo],
            mandatory = True,
        ),
        "replacements": attr.label_keyed_string_dict(
            doc = """replacements for dependencies of node_module (in case they are also ESM only).

            Keys are the replacements (must be created by transpile_esm_to_cjs as well),
            values are the names of the package to be replaced.
            """,
            providers = [JsInfo, _TranspileInfo],
        ),
        "_transpiler": attr.label(
            executable = True,
            cfg = "exec",
            default = Label("//private/hacks/src:transpile-esm-to-cjs"),
        ),
    },
)
