"""ibazel_info repository rule: allows to detect whether we run under ibazel"""

def _ibazel_info_impl(ctx):
    is_ibazel = "IBAZEL" in ctx.os.environ

    ctx.file("BUILD", "\n".join([
        """load("@bazel_skylib//:bzl_library.bzl", "bzl_library")""",
        """bzl_library(""",
        """  name = "bzl",""",
        """  srcs = glob(["**/*.bzl"]),""",
        """  visibility = ["//visibility:public"],""",
        """)""",
    ]))

    ctx.file("is_ibazel.bzl", "is_ibazel = {}".format(is_ibazel))

ibazel_info = repository_rule(
    implementation = _ibazel_info_impl,
    environ = ["IBAZEL"],
)
