"""Utilities to post process the raw result output directory."""

load("@bazel_lib//lib:copy_to_directory.bzl", "copy_to_directory")
load("@bazel_skylib//rules:write_file.bzl", "write_file")

def declare_commonjs(name, raw_result, out_dir, allow_overwrite = False, testonly = None):
    """Declares the output directory to be a CommonJS module by putting a package.json in it.

    Args:
      name: Name of the resulting rule.
      raw_result: Result directory (from prisma_generator_result). Must be a
        label and a relative directory name (no leading `:`).
      out_dir: Directory to write to.
      allow_overwrite: Whether to allow overwriting an existing package.json
      testonly: testonly flag.
    """

    write_file(
        name = name + ".pkg",
        out = name + ".pkg/package.json",
        content = ["""{"type": "commonjs"}"""],
    )

    copy_to_directory(
        name = name,
        allow_overwrites = allow_overwrite,
        srcs = [
            raw_result,
            name + ".pkg",
        ],
        replace_prefixes = {
            # Use the result output directory as "new root",
            raw_result: "",
            # Put the package json in the same directory.
            name + ".pkg": "",
        },
        out = out_dir,
        testonly = testonly,
    )
