"""convenience rule to write formatted file to source directory."""

load("@aspect_bazel_lib//lib:write_source_files.bzl", "write_source_file")
load(":npm_js_binary.bzl", "npm_js_binary")

def write_source_file_prettier(name, in_file, out_file, testonly = None):
    """Convenience rule to format write_source_file with prettier first.

    Args:
      name: Name prefix
      in_file: File to format and then write.
      out_file: File to write.
      testonly: Testonly flag.
    """

    prettier = name + ".prettier"
    npm_js_binary(
        name = name + ".prettier",
        entry_point = "./bin/prettier.cjs",
        node_module = "prettier",
        testonly = testonly,
    )

    # Use a genrule instead of js_run_binary because we need redirection:
    # Prettier refuses to format symlinks (starting 3.x), so we pipe the file
    # we want to format (but js_run_binary doesn't support stdin piping).
    native.genrule(
        name = name + ".fmt",
        cmd = "BAZEL_BINDIR=. $(location %s) --stdin-filepath $< < $< > $@" % prettier,
        srcs = [in_file],
        outs = [name + ".fmtted"],
        tools = [prettier],
        testonly = testonly,
    )

    write_source_file(
        name = name + ".write",
        in_file = name + ".fmt",
        out_file = out_file,
        testonly = testonly,
    )
