"""The core, required setup macro without the npm_link_all_packages invocation.

We split npm_link_all_packages out so we can use this internal rule for dh_buildlib itself.
For dh_buildlib, npm_link_all_packages comes from a different repository, so we need
a custom `load` statement.
"""

load("@aspect_bazel_lib//lib:write_source_files.bzl", "write_source_files")
load("//private/setup/ts:ts_setup.bzl", "ts_setup")
load(":core_setup.bzl", "core_setup")

def buildlib_setup_no_npm(
        name,
        enable_ts = False):
    # buildifier: disable=function-docstring-args
    """See docs on buildlib/setup/defs/buildlib_setup.bzl"""

    if name != "buildlib_setup":
        fail("name must be buildlib_setup, got: %s" % name)

    if native.package_name() != "":
        fail("buildlib_setup must be in the root package")

    update_targets = []

    core_setup(update_targets)

    if enable_ts:
        ts_setup(update_targets)

    write_source_files(
        name = "buildlib_setup.write",
        additional_update_targets = update_targets,
    )
