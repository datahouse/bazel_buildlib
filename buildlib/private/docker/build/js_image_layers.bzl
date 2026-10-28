"""buildlib internal rules to build layers for JS images (for node apps)."""

load("@aspect_rules_js//js:libs.bzl", "js_lib_helpers")
load("@aspect_rules_js//js:providers.bzl", "JsInfo")
load("@tar.bzl//tar:tar.bzl", "tar")

def _node_image_transition_impl(_settings, attr):
    return {
        # Transition into the right target platform.
        "//command_line_option:platforms": str(attr.platform),
    }

_node_image_transition = transition(
    implementation = _node_image_transition_impl,
    inputs = [],
    outputs = [
        "//command_line_option:platforms",
    ],
)

def _build_js_image_layer(ctx, suffix, files, output):
    entries_file = ctx.actions.declare_file("{}_entries_{}.json".format(ctx.label.name, suffix))

    entries = [
        {
            "isDirectory": f.is_directory,
            "isSource": f.is_source,
            "root": f.root.path,
            "shortPath": f.short_path,
            "srcPath": f.path,
        }
        for f in files
    ]

    ctx.actions.write(entries_file, content = json.encode(entries))

    ctx.actions.run(
        inputs = [entries_file] + files,
        outputs = [output],
        arguments = [entries_file.path, output.path],
        executable = ctx.executable._builder,
        progress_message = "JsImageLayerMtree %{label} (" + suffix + ")",
        env = {
            "BAZEL_BINDIR": ".",
        },
    )

def _js_image_layer_mtree_impl(ctx):
    # Split node modules / app files in the rule, so we do not have to rebuild
    # the node_modules tar if only the app changes.
    node_modules_files = []
    app_files = []

    # Depset to gather files necessary to run the application - application files
    # plus transitive dependencies. Set may contain duplicates.
    #
    # Duplicates can arise because the `owner` of the File can be different (while
    # everything else is the same). This can happen as a result of multiple rules
    # forwarding the same files downstream.
    #
    # LayerBuilder is equipped to deduplicate the files if they have the same paths.
    #
    # For example, tsc_target_name here:
    # https://github.com/aspect-build/rules_ts/blob/dc5f4549cffae844166620e81bbff9acf7e66428/ts/defs.bzl#L396
    files = depset(transitive = [
        js_lib_helpers.gather_files_from_js_infos(
            ctx.attr.data,
            include_sources = True,
            include_transitive_sources = True,
            include_npm_sources = True,
            include_types = False,
            include_transitive_types = False,
        ),
    ] + [
        d[DefaultInfo].default_runfiles.files
        for d in ctx.attr.data
    ])

    for f in files.to_list():
        if "/node_modules/" in f.path:
            node_modules_files.append(f)
        else:
            app_files.append(f)

    output_groups = {}

    if ctx.outputs.node_modules_mtree:
        _build_js_image_layer(ctx, "node_modules", node_modules_files, ctx.outputs.node_modules_mtree)
        output_groups["node_modules_files"] = depset(node_modules_files)

    if ctx.outputs.app_mtree:
        _build_js_image_layer(ctx, "app", app_files, ctx.outputs.app_mtree)
        output_groups["app_files"] = depset(app_files)

    return [
        OutputGroupInfo(**output_groups),
    ]

_js_image_layer_mtree = rule(
    doc = """Build mtree specs for two JS layers from the runfiles:
    - One containing the node_modules
    - One containing the app files

    The files referenced by each mtree spec are exposed via the `app_files` /
    `node_modules_files` output groups, for `js_image_layers` to feed (via a
    `filegroup`) to the `tar` rule.
    """,
    attrs = {
        "app_mtree": attr.output(),
        "data": attr.label_list(
            providers = [JsInfo],
            mandatory = True,
        ),
        "node_modules_mtree": attr.output(),
        "platform": attr.label(
            doc = "Target platform",
            mandatory = True,
        ),
        "_allowlist_function_transition": attr.label(
            default = "@bazel_tools//tools/allowlists/function_transition_allowlist",
        ),
        "_builder": attr.label(
            default = Label("//private/docker/build/src:js-image-layer"),
            executable = True,
            cfg = "exec",
        ),
    },
    implementation = _js_image_layer_mtree_impl,
    cfg = _node_image_transition,
)

def js_image_layers(name, data, platform, app_layer = None, node_modules_layer = None, testonly = None):
    """Build two JS layer tars from the runfiles:

    - One containing the node_modules
    - One containing the app files

    Note: Not a symbolic macro because of the output attributes (app_layer, node_modules_layer).

    Args:
        name: name of this target
        data: ts_project(s) (or other JsInfo providers) to build the layers from
        platform: target platform (see the _js_image_layer_mtree rule)
        app_layer: output filename for the app layer tar (skipped if not set)
        node_modules_layer: output filename for the node_modules layer tar (skipped if not set)
        testonly: testonly flag
    """
    _js_image_layer_mtree(
        name = name + ".mtree",
        data = data,
        platform = platform,
        app_mtree = (name + ".app.mtree_spec") if app_layer else None,
        node_modules_mtree = (name + ".node-modules.mtree_spec") if node_modules_layer else None,
        testonly = testonly,
    )

    if app_layer:
        native.filegroup(
            name = name + ".app_files",
            srcs = [name + ".mtree"],
            output_group = "app_files",
            testonly = testonly,
        )

        tar(
            name = name + ".app_tar",
            out = app_layer,
            compress = "gzip",
            srcs = [name + ".app_files"],
            mtree = name + ".app.mtree_spec",
            testonly = testonly,
        )

    if node_modules_layer:
        native.filegroup(
            name = name + ".node_modules_files",
            srcs = [name + ".mtree"],
            output_group = "node_modules_files",
            testonly = testonly,
        )

        tar(
            name = name + ".node_modules_tar",
            out = node_modules_layer,
            compress = "gzip",
            srcs = [name + ".node_modules_files"],
            mtree = name + ".node-modules.mtree_spec",
            testonly = testonly,
        )
