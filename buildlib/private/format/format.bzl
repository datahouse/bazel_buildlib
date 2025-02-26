"""Rules to run formatters / test formatting."""

load("@aspect_rules_js//js:defs.bzl", "js_binary")
load("//private:npm_js_binary.bzl", "npm_js_binary")

def format(name):
    """Rule to format code.

    Example: [`@examples//:format`](../../examples/BUILD.bazel#:~:text=name%20%3D%20%22format%22)

    The target must be called `format` and in the root package.

    Supported formatters:
    - [Prettier](https://prettier.io/)
    - [Buildifier](https://github.com/bazelbuild/buildtools/blob/master/buildifier/README.md)

    To format:

    ```sh
    bazel run //:format
    ```

    To check formatting:

    ```sh
    bazel run //:format -- --check
    ```

    Args:
      name: Name of the genreated rule, must be "format"
    """

    if name != "format":
        fail("name must be format got: %s" % name)

    if native.package_name() != "":
        fail("format must be in the root package")

    npm_js_binary(
        name = name + ".prettier",
        entry_point = "./bin/prettier.cjs",
        node_module = "prettier",
    )

    # Resolve label in the defining workspace (not the calling workspace).
    buildifier = Label("@buildifier_prebuilt//:buildifier")

    js_binary(
        name = name,
        data = [
            Label("//private/format/src"),
            name + ".prettier",
            buildifier,
        ],
        copy_data_to_bin = False,
        entry_point = Label("//private/format/src:format.js"),
        env = {
            "BAZEL_BINDIR": ".",
            "BUILDIFIER_BIN": "$(rootpath %s)" % buildifier,
            "PRETTIER_BIN": "$(rootpath format.prettier)",
        },
    )

    native.sh_test(
        name = name + ".test",
        srcs = [Label(":format-test.sh")],
        data = [name, "//:.bazelrc"],
        env = {
            "DH_FORMAT_SCRIPT": "$(rootpath %s)" % name,
            # Pass any file in the workspace root to determine its locaiton.
            "FILE_IN_WORKSPACE": "$(location //:.bazelrc)",
        },
        tags = ["local", "external"],
    )
