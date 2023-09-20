"""Bazelrc rule."""

load("@aspect_bazel_lib//lib:utils.bzl", "file_exists")
load("@aspect_bazel_lib//lib:write_source_files.bzl", "write_source_file")

def bazelrc(name):
    """Rule to test bazel / bazelisk config is according to Datahouse standards.

    Must be in the repository root.

    Example: [`@examples//:bazelrc`](../../examples/BUILD.bazel#:~:text=name%20%3D%20%22bazelrc%22%2C)

    Args:
      name: Name of the rule, must be "bazelrc".
    """

    if name != "bazelrc":
        fail("name must be bazelrc got: %s" % name)

    if native.package_name() != "":
        fail("bazelrc must be in the root package")

    if not file_exists(".bazelversion"):
        fail("there must be a .bazelversion file to pin the bazel version for bazelisk")

    write_source_file(
        name = name,
        in_file = Label(":default.bazelrc"),
        out_file = ".bazelrc",
    )
