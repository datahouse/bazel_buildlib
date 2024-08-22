"""Buildifier repositoriy rules (to download buildifier)."""

load(":buildifier.bzl", "BASE_URL", "PLATFORMS")

def _buildifier_platform_repo_impl(rctx):
    rctx.download(
        url = rctx.attr.url,
        output = "buildifier",
        executable = True,
        integrity = rctx.attr.integrity,
    )

    build_content = "\n".join([
        """load("@dh_buildlib//private/format:toolchains.bzl", "buildifier_toolchain")""",
        """buildifier_toolchain(""",
        """  name = "buildifier_toolchain",""",
        """  bin = "buildifier",""",
        """  visibility = ["//visibility:public"],""",
        """)""",
    ])

    rctx.file("BUILD.bazel", build_content)

_buildifier_platform_repo = repository_rule(
    implementation = _buildifier_platform_repo_impl,
    doc = "Fetches buildifier.",
    attrs = {
        "integrity": attr.string(),
        "url": attr.string(),
    },
)

# False positive due to register_toolchains
# buildifier: disable=unnamed-macro
def buildifier_repos():
    for platform, info in PLATFORMS.items():
        _buildifier_platform_repo(
            name = "dh_buildlib_private_buildifier_" + platform,
            integrity = info.integrity,
            url = BASE_URL + platform,
        )

        native.register_toolchains(
            "@dh_buildlib//private/format:buildifier_" + platform,
        )
