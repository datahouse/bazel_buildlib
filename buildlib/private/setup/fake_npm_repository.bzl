"""Fake npm repository rule to be able to generate stardoc for buildlib_setup.

See the comment on setup/defs/buildlib_setup.bzl for more.
"""

def _fake_npm_repository_impl(ctx):
    ctx.file("defs.bzl", "def npm_link_all_packages(name):\n  pass\n")
    ctx.file("BUILD", """exports_files(["defs.bzl"])""")

fake_npm_repository = repository_rule(
    implementation = _fake_npm_repository_impl,
)
