"""Eslint macro (buildlib internal)

This is merely separate from library.bzl for readability purposes.
"""

load("@aspect_rules_js//js:defs.bzl", "js_binary", "js_test")
load("@bazel_lib//lib:utils.bzl", "to_label")

def eslint(name, srcs, deps, tags = [], testonly = None):
    """Runs eslint on the given sources.

    Args:
      name: Name of the test rule (the fix rule will have `.fix` appended).
      srcs: Sources to lint.
      deps: Compile time dependencies for srcs.
      tags: tags, propagated to all targets
      testonly: Testonly flag
    """

    entry_point = Label("//private/ts/eslint-runner:run-eslint.js")

    data = srcs + deps + [
        Label("//private/ts/eslint-runner"),
        ":tsconfig",
        "//:eslint_config",
        # Dependencies of the DH default config.
        # Adding user dependencies is currently not supported.
        "//:node_modules/globals",
        "//:node_modules/@eslint/js",
        "//:node_modules/@eslint/eslintrc",
        "//:node_modules/eslint",
        "//:node_modules/eslint-config-airbnb",
        "//:node_modules/eslint-config-prettier",
        "//:node_modules/eslint-plugin-import",
        "//:node_modules/eslint-plugin-react",
        "//:node_modules/eslint-plugin-jest",
        "//:node_modules/eslint-plugin-react-hooks",
        "//:node_modules/eslint-plugin-jsx-a11y",
        "//:node_modules/typescript-eslint",
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
        tags = tags,
        testonly = testonly,
    )

    js_binary(
        name = name + ".fix",
        args = ["--fix"] + common_args,
        entry_point = entry_point,
        data = data,
        tags = tags,
        testonly = testonly,
    )
