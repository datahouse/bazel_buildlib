"""Toolchain definitions for formatters."""

BuildifierInfo = provider(
    doc = "Buildifier toolchain info",
    fields = {
        "bin": "Executable buildifier binary",
    },
)

def _buildifier_toolchain_impl(ctx):
    toolchain_info = platform_common.ToolchainInfo(
        buildifierinfo = BuildifierInfo(
            bin = ctx.file.bin,
        ),
    )
    return [toolchain_info]

buildifier_toolchain = rule(
    implementation = _buildifier_toolchain_impl,
    attrs = {
        "bin": attr.label(
            mandatory = True,
            allow_single_file = True,
            executable = True,
            cfg = "exec",
        ),
    },
)
