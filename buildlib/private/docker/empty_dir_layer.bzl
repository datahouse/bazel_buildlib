"""Macro to create a docker image layer containing empty directories."""

def _empty_dir_layer_impl(ctx):
    args = ctx.actions.args()

    args.add("--base", ctx.file.base.path)
    args.add_all("--path", ctx.attr.paths)
    args.add("--user", ctx.attr.user)
    args.add("--output", ctx.outputs.out)

    ctx.actions.run(
        inputs = [ctx.file.base],
        outputs = [ctx.outputs.out],
        arguments = [args],
        executable = ctx.executable._builder,
        env = {"BAZEL_BINDIR": "."},
    )

empty_dir_layer = rule(
    attrs = {
        "base": attr.label(allow_single_file = True),
        "out": attr.output(),
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
