"""Rules for eslint."""

load("@aspect_rules_js//js:defs.bzl", "js_library", "js_test")
load("@bazel_skylib//rules:copy_file.bzl", "copy_file")

def eslintrc(name, visibility = None):
    """Declares an eslintrc file.

    The following source files are implicititly depended on:
    - .eslintrc.js (main config)
    - .eslintignore (if it exists)
    - package.json
    - tsconfig-base.json

    Provides a test that ensures the eslintrc includes the Datahouse base eslint
    config.

    Example: [`@examples//:eslintrc`](../../examples/BUILD.bazel#:~:text=name%20%3D%20%22eslintrc%22%2C)

    Args:
      name: Name of the rule. Must be "eslintrc".
      visibility: Visibility of the eslintrc rule.
    """

    if name != "eslintrc":
        fail("name must be 'eslintrc'")

    # We copy the eslint defaults twice.
    # - Once to the source directory, so the IDEs find it.
    # - Once to a nested directory bazel-bin, so eslint finds it when running
    #   under bazel (in the source directory). This is somewhat of a hack.
    #
    # Lastly, we carefully chose the dependency tree, so that the file for the IDEs
    # is copied whenever we lint anything (so it doesn't need to be built explicitly).

    copy_file(
        name = "eslintrc.defaults",
        src = Label(":eslint.dh-defaults.js"),
        out = "eslintrc.dh-defaults.js",
    )

    copy_file(
        name = "eslintrc.defaults.bin",
        src = ":eslintrc.defaults",
        out = "bazel-bin/eslintrc.dh-defaults.js",
    )

    js_library(
        name = name,
        srcs = [
            ".eslintrc.js",
            "eslintrc.defaults.bin",
            # Add package.json.
            #
            # eslint-plugin-import (transitive dependency of AirBnB) requires the
            # package.json to find the package root:
            # https://github.com/import-js/eslint-plugin-import/blob/d1602854ea9842082f48c51da869f3e3b70d1ef9/src/core/packagePath.js#L11
            #
            # Otherwise, `pkgUp` returns `null`, making the call to `basename` fail.
            "package.json",
            ":tsconfig-base",
        ],
        visibility = visibility,
    )

    js_test(
        name = name + ".test",
        args = ["./.eslintrc.js"],
        data = [Label("//private/ts/src"), ".eslintrc.js"],
        entry_point = Label("//private/ts/src:check-eslintrc.js"),
    )
