"""internal macro to DRY up document generation."""

load("@bazel_skylib//:bzl_library.bzl", "bzl_library")

def bzl_lib_for_docs(name, deps = []):
    """bzl_library target and exports_files for stardoc.

    We do not want to refer to stardoc directly from the main packages:
    if we do that, loading fails when dh_buildlib is loaded from another module,
    because stardoc is only a dev dependency.

    Therefore, we expose the file and a bzl_library to //docs:__pkg__ and invoke
    stardoc there.

    Args:
      name: base name of the file to document.
      deps: dependencies.
    """

    srcs = [name + ".bzl"]

    native.exports_files(
        srcs = srcs,
        visibility = ["//docs:__pkg__"],
    )

    bzl_library(
        name = name,
        srcs = srcs,
        deps = deps,
        visibility = ["//docs:__pkg__"],
    )
