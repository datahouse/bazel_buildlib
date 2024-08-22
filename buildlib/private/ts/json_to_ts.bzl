"""json_to_ts macro"""

load("@bazel_skylib//lib:paths.bzl", "paths")
load("@bazel_skylib//rules:write_file.bzl", "write_file")

def json_to_ts(name, src, out = None, type = None, type_imports = [], visibility = None, testonly = None):
    """Convert JSON to Typescript.

    Produces a typescript file with a single default export containing the JSON data.

    Example: [`@buildlib//private/ts/test:data`](../private/ts/test/BUILD.bazel#:~:text=name%20%3D%20%22data%22%2C)

    Args:
      name: Name of the resulting rule.
      src: JSON file to convert to typescript (must end in .json)
      out: Output file name (defaults to src with .ts extension).
      type: Optional type annotation for the type (e.g. `string`).
      type_imports: Optional import line(s) for the type (e.g. `import type { X } from "./x.js";`).
      visibility: Visibility specifier.
      testonly: testonly flag.
    """

    if not src.endswith(".json"):
        fail("src must end with .json")

    if not out:
        out = paths.replace_extension(src, ".ts")

    val_def = "const value = "
    if type:
        val_def = "const value: {} = ".format(type)

    import_lines = []
    if type_imports:
        # Add empty line for eslint.
        import_lines = type_imports + [""]

    write_file(
        name = name + "_prefix",
        out = name + "_prefix.txt",
        content = import_lines + [val_def],
        testonly = testonly,
    )

    write_file(
        name = name + "_suffix",
        out = name + "_suffix.txt",
        content = [
            ";",
            "export default value;",
            "",
        ],
        testonly = testonly,
    )

    native.genrule(
        name = name,
        srcs = [
            name + "_prefix.txt",
            src,
            name + "_suffix.txt",
        ],
        outs = [out],
        cmd = "cat $(SRCS) > $@",
        visibility = visibility,
        testonly = testonly,
    )
