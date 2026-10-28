"""Private rules for my-version."""

load("@bazel_lib//lib:stamping.bzl", "STAMP_ATTRS", "maybe_stamp")

visibility("private")

def _gen_my_version_impl(ctx):
    stamp = maybe_stamp(ctx)

    if stamp:
        args = ctx.actions.args()

        args.add("--stableStatusFile", stamp.stable_status_file)
        args.add("--volatileStatusFile", stamp.volatile_status_file)
        args.add("--output", ctx.outputs.out)

        ctx.actions.run(
            inputs = [
                stamp.stable_status_file,
                stamp.volatile_status_file,
            ],
            outputs = [ctx.outputs.out],
            arguments = [args],
            env = {"BAZEL_BINDIR": "."},
            executable = ctx.executable._builder,
        )
    else:
        ctx.actions.write(ctx.outputs.out, "<unstamped bazel build>")

gen_my_version = rule(
    implementation = _gen_my_version_impl,
    attrs = dict({
        "out": attr.output(),
        "_builder": attr.label(
            default = "//private/my-version/src:gen-my-version",
            executable = True,
            cfg = "exec",
        ),
    }, **STAMP_ATTRS),
)
