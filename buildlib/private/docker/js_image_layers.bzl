"""buildlib internal rules to build layers for JS images (for node apps)."""

load("@aspect_rules_js//js:providers.bzl", "JsInfo")

def _node_image_transition_impl(_settings, attr):
    return {
        # Transition into the right target platform.
        "//command_line_option:platforms": str(attr.platform),
        # Make sure we're getting commonjs modules.
        #
        # Our code does not work with the default node esm resolver
        # (we do not have file extensions).
        "//private/ts:module": "commonjs",
    }

_node_image_transition = transition(
    implementation = _node_image_transition_impl,
    inputs = [],
    outputs = [
        "//command_line_option:platforms",
        "//private/ts:module",
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
        progress_message = "JsImageLayer %{label} (" + suffix + ")",
        env = {
            "BAZEL_BINDIR": ".",
        },
    )

def _js_image_layer_impl(ctx):
    # Split node modules / app files in the rule, so we do not have to rebuild
    # the node_modules tar if only the app changes.
    node_modules_files = []
    app_files = []

    # Intermediate depset to remove duplicates.
    #
    # Note that despite this, duplicates can appear duplicate in the resulting
    # depset: This is because the `owner` of the File can be different (while
    # everything else is the same). This can happen as a result of multiple rules
    # forwarding the same files downstream.
    #
    # LayerBuilder is equipped to deduplicate the files if they have the same paths.
    #
    # For example, tsc_target_name here:
    # https://github.com/aspect-build/rules_ts/blob/dc5f4549cffae844166620e81bbff9acf7e66428/ts/defs.bzl#L396
    files = depset(transitive = [
        d[DefaultInfo].default_runfiles.files
        for d in ctx.attr.data
    ])

    for f in files.to_list():
        if "/node_modules/" in f.path:
            node_modules_files.append(f)
        else:
            app_files.append(f)

    if ctx.outputs.node_modules_layer:
        _build_js_image_layer(ctx, "node_modules", node_modules_files, ctx.outputs.node_modules_layer)

    if ctx.outputs.app_layer:
        _build_js_image_layer(ctx, "app", app_files, ctx.outputs.app_layer)

js_image_layers = rule(
    doc = """Build two JS layers from the runfiles:
    - One containing the node_modules
    - One containing the app files
    """,
    attrs = {
        "app_layer": attr.output(),
        "data": attr.label_list(
            providers = [JsInfo],  # not used, but prevents bad usage.
            mandatory = True,
        ),
        "node_modules_layer": attr.output(),
        "platform": attr.label(
            doc = "Target platform",
            mandatory = True,
        ),
        "_allowlist_function_transition": attr.label(
            default = "@bazel_tools//tools/allowlists/function_transition_allowlist",
        ),
        "_builder": attr.label(
            default = Label("//private/docker/src:js-image-layer"),
            executable = True,
            cfg = "exec",
        ),
    },
    implementation = _js_image_layer_impl,
    cfg = _node_image_transition,
)
