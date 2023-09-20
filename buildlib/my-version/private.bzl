"""Private rules for my-version."""

load("@rules_nodejs//nodejs:providers.bzl", "STAMP_ATTR", "StampSettingInfo")

visibility("private")

def _gen_my_version_impl(ctx):
    stamp = ctx.attr._stamp[StampSettingInfo].value

    if stamp:
        ctx.actions.run(
            inputs = [ctx.info_file],
            outputs = [ctx.outputs.out],
            arguments = ["--info-file", ctx.info_file.path, ctx.outputs.out.path],
            env = {"BAZEL_BINDIR": "."},
            executable = ctx.executable._builder,
        )
    else:
        ctx.actions.write(ctx.outputs.out, "<unstamped bazel build>")

gen_my_version = rule(
    implementation = _gen_my_version_impl,
    attrs = {
        "out": attr.output(),
        "_builder": attr.label(
            default = "//private/my-version/src:gen-my-version",
            executable = True,
            cfg = "exec",
        ),
        "_stamp": STAMP_ATTR,
    },
)
