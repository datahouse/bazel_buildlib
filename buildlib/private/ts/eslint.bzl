"""Eslint macro (buildlib internal)

This is merely separate from library.bzl for readability purposes.
"""

load("@aspect_bazel_lib//lib:utils.bzl", "to_label")
load(":js_binary.bzl", "js_binary", "js_test")

def eslint(name, srcs, deps, testonly = None):
    """Runs eslint on the given sources.

    Args:
      name: Name of the test rule (the fix rule will have `.fix` appended).
      srcs: Sources to lint.
      deps: Compile time dependencies for srcs.
      testonly: Testonly flag
    """

    entry_point = Label("//private/ts/src:run-eslint.js")

    data = srcs + deps + [
        Label("//private/ts/src"),
        ":tsconfig",
        "//:eslintrc",
        "//:node_modules/eslint",
        "//:node_modules/@typescript-eslint/eslint-plugin",
        "//:node_modules/@typescript-eslint/parser",
        "//:node_modules/eslint-config-airbnb",
        "//:node_modules/eslint-config-airbnb-typescript",
        "//:node_modules/eslint-config-prettier",
        "//:node_modules/eslint-plugin-import",
        "//:node_modules/eslint-plugin-react",
        "//:node_modules/eslint-plugin-jest",
        "//:node_modules/eslint-plugin-react-hooks",
        "//:node_modules/eslint-plugin-jsx-a11y",
    ]

    common_args = [
        "--fixTargetName",
        str(to_label(name + ".fix")),
    ] + [
        "$(rootpaths %s)" % src
        for src in srcs
    ]

    js_test(
        name = name,
        args = common_args,
        entry_point = entry_point,
        data = data,
        testonly = testonly,
    )

    js_binary(
        name = name + ".fix",
        args = ["--fix"] + common_args,
        entry_point = entry_point,
        data = data,
        testonly = testonly,
    )
