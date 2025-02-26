"""Convenience rule to format a file with prettier."""

load(":npm_js_binary.bzl", "npm_js_binary")

def prettier_format(name, src, out, testonly = None, visibility = None):
    """Convenience rule to format a file with prettier."""

    prettier = name + ".prettier"
    npm_js_binary(
        name = prettier,
        entry_point = "./bin/prettier.cjs",
        node_module = "prettier",
        testonly = testonly,
    )

    # Use a genrule instead of js_run_binary because we need redirection:
    # Prettier refuses to format symlinks (starting 3.x), so we pipe the file
    # we want to format (but js_run_binary doesn't support stdin piping).
    native.genrule(
        name = name,
        cmd = "BAZEL_BINDIR=. $(location %s) --stdin-filepath $< < $< > $@" % prettier,
        srcs = [src],
        outs = [out],
        tools = [prettier],
        testonly = testonly,
        visibility = visibility,
    )
