"""Rules to run formatters / test formatting."""

load("@aspect_rules_js//js:defs.bzl", "js_binary")
load("//private/ts:npm_js_binary.bzl", "npm_js_binary")

def _buildifier_impl(ctx):
    buildifier = ctx.toolchains[":buildifier_toolchain_type"].buildifierinfo.bin
    return DefaultInfo(files = depset([buildifier]))

_buildifier = rule(
    doc = "helper rule to retrieve the bulidifier toolchain",
    implementation = _buildifier_impl,
    toolchains = [":buildifier_toolchain_type"],
)

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

    _buildifier(
        name = name + ".buildifier",
    )

    js_binary(
        name = name,
        data = [
            Label("//private/format/src"),
            name + ".prettier",
            name + ".buildifier",
        ],
        copy_data_to_bin = False,
        entry_point = Label("//private/format/src:format.js"),
        env = {
            "BAZEL_BINDIR": ".",
            "BUILDIFIER_BIN": "$(rootpath format.buildifier)",
            "PRETTIER_BIN": "$(rootpath format.prettier)",
        },
    )

    # To test this rule locally, do:
    #
    #     DH_BUILDLIB_FORMAT_CHECK_DIR=$PWD bazel test //:format.ci_test
    #
    native.sh_test(
        name = name + ".ci_test",
        srcs = [Label(":ci-format-test.sh")],
        data = [name],
        env_inherit = ["DH_BUILDLIB_FORMAT_CHECK_DIR"],
        env = {"DH_FORMAT_SCRIPT": "$(rootpath %s)" % name},
        tags = ["local", "external"],
    )
