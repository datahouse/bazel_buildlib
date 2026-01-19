"""Toolchain rule and provider for docker compose binary toolchain"""

ComposeBinaryInfo = provider(
    doc = """Provider for docker compose binary""",
    fields = {
        "compose_bin": "The docker compose binary (executable file)",
    },
)

def _compose_bin_toolchain_impl(ctx):
    toolchain_info = platform_common.ToolchainInfo(
        compose_binary = ComposeBinaryInfo(
            compose_bin = ctx.executable.compose_bin,
        ),
    )
    return [toolchain_info]

compose_bin_toolchain = rule(
    implementation = _compose_bin_toolchain_impl,
    attrs = {
        "compose_bin": attr.label(
            allow_single_file = True,
            mandatory = True,
            executable = True,
            cfg = "target",
        ),
    },
)
