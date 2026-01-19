"""Repository rule for docker compose repository"""

def _compose_repository_impl(ctx):
    ctx.download(
        url = [ctx.attr.url],
        output = "docker_compose",
        sha256 = ctx.attr.sha256,
        executable = True,
    )

    ctx.file("BUILD", "\n".join([
        """load("@dh_buildlib//private/docker/compose:compose_toolchain.bzl", "compose_bin_toolchain")""",
        """compose_bin_toolchain(name = "toolchain", compose_bin = ":docker_compose")""",
    ]))

compose_repository = repository_rule(
    implementation = _compose_repository_impl,
    attrs = {
        "sha256": attr.string(mandatory = True),
        "url": attr.string(mandatory = True),
    },
)
