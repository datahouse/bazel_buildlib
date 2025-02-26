"""Language independent setup."""

load("@aspect_bazel_lib//lib:utils.bzl", "utils")
load("//private/format:format.bzl", "format")
load("//private/setup:write_setup_source_file.bzl", "write_setup_source_file")
load("//private/setup/npm:npm_setup.bzl", "npm_setup")
load("//private/setup/renovate:renovate.bzl", "renovate_setup")

# buildifier: disable=unnamed-macro (private)
def core_setup(update_targets):
    _bazelrc_setup(update_targets)

    # npm is always required because we need at least prettier.
    # It does not make sense to make, say, .md formatting optional.
    npm_setup(update_targets)

    renovate_setup(update_targets)  # autodetect

    format(name = "format")  # no update targets, format has its own test.

def _bazelrc_setup(update_targets):
    if not utils.file_exists(".bazelversion"):
        fail("there must be a .bazelversion file to pin the bazel version for bazelisk")

    write_setup_source_file(
        name = "bazelrc",
        in_file = Label(":default.bazelrc"),
        out_file = ".bazelrc",
        update_targets = update_targets,
    )
