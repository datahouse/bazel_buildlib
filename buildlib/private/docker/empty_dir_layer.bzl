"""Macro to create a docker image layer containing empty directories."""

def _empty_dir_layer_impl(ctx):
    args = ctx.actions.args()

    args.add("--passwd", ctx.file.passwd)
    args.add_all("--path", ctx.attr.paths)
    args.add("--user", ctx.attr.user)
    args.add("--output", ctx.outputs.out)

    ctx.actions.run(
        inputs = [ctx.file.passwd],
        outputs = [ctx.outputs.out],
        arguments = [args],
        executable = ctx.executable._builder,
        env = {"BAZEL_BINDIR": "."},
    )

empty_dir_layer = rule(
    attrs = {
        "out": attr.output(),
        "passwd": attr.label(allow_single_file = True),
        "paths": attr.string_list(),
        "user": attr.string(),
        "_builder": attr.label(
            default = Label("//private/docker/src:empty-dir-layer"),
            executable = True,
            cfg = "exec",
        ),
    },
    implementation = _empty_dir_layer_impl,
)
