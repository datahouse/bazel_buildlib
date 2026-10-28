"""Rule to build the mtree spec (for the `tar` rule) of a docker image layer containing empty directories.

Note: This is a rule, rather than just a js_run_binary invocation to keep its
attributes configurable (notably `user`, which might depend on a configurable image).
"""

def _empty_dir_layer_mtree_impl(ctx):
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

empty_dir_layer_mtree = rule(
    attrs = {
        "out": attr.output(),
        "passwd": attr.label(allow_single_file = True),
        "paths": attr.string_list(),
        "user": attr.string(),
        "_builder": attr.label(
            default = Label("//private/docker/build/src:empty-dir-layer-mtree"),
            executable = True,
            cfg = "exec",
        ),
    },
    implementation = _empty_dir_layer_mtree_impl,
)
