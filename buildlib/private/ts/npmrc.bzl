""" Npmrc rule """

load("@aspect_bazel_lib//lib:write_source_files.bzl", "write_source_file")

def npmrc(name):
    """Rule to test npm config is according to Datahouse standards.

    Must be in the repository root.

    Example: See [`ts_setup`](#ts_setup)

    Args:
      name: Name of the rule, must be "npmrc".
    """

    if name != "npmrc":
        fail("name must be npmrc, got: %s" % name)

    if native.package_name() != "":
        fail("npmrc must be in the root package")

    write_source_file(
        name = name,
        in_file = Label(":default.npmrc"),
        out_file = ".npmrc",
    )
