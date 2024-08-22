"""internal stardoc rule"""

load("@io_bazel_stardoc//stardoc:stardoc.bzl", _stardoc = "stardoc")

_prefix = "docs_"

def stardoc(name, deps = []):
    """Opinionated wrapper around stardoc.

    Args:
      name: name of the rule, must be "doc_<bzl-base>",
        where <bzl-base>.def is the starlark file to create the docs of.
      deps: dependencies.
    """

    if not name.startswith(_prefix):
        fail("name must start with %s" % _prefix)

    base = name.removeprefix(_prefix)

    _stardoc(
        name = name,
        out = base + ".md",
        input = base + ".bzl",
        visibility = ["//docs:__pkg__"],
        table_of_contents_template = "@io_bazel_stardoc//stardoc:templates/markdown_tables/table_of_contents.vm",
        deps = deps,
    )
