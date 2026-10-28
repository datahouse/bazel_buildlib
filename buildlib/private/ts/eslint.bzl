"""Eslint macro (buildlib internal)

This is merely separate from library.bzl for readability purposes.
"""

load("@aspect_rules_js//js:defs.bzl", "js_binary", "js_info_files", "js_test")
load("@bazel_lib//lib:utils.bzl", "to_label")

def _eslint_impl(
        name,
        srcs,
        deps,
        tsconfig,
        eslint_config,
        tags,
        testonly,
        visibility):  # @unused lint targets are private by design.
    entry_point = Label("//private/ts/eslint-runner:run-eslint.js")

    # Collect srcs in a filegroup so they can be passed with a single
    # $(rootpaths) expansion (keeps srcs configurable).
    native.filegroup(
        name = name + ".srcs",
        srcs = srcs,
        tags = tags,
        testonly = testonly,
    )

    # Gather types from srcs & deps for type aware linter rules.
    #
    # Note: We could instead set `include_transitive_types = True` on the
    # js_test / js_binary invocation below.
    # However, that would also try to pull types from the eslint runner which
    # fails because of the somewhat hacked ts_library setup.
    # Since we do not need these types, we just do not include them.
    js_info_files(
        name = name + ".types",
        srcs = srcs + deps,
        include_transitive_types = True,
        testonly = testonly,
    )

    data = deps + [
        name + ".srcs",
        name + ".types",
        Label("//private/ts/eslint-runner"),
        tsconfig,
        eslint_config,
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
        "$(rootpaths :%s.srcs)" % name,
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

eslint = macro(
    doc = "Runs eslint on the given sources (the fix target has `.fix` appended).",
    attrs = {
        "deps": attr.label_list(doc = "Compile time dependencies for srcs."),
        "eslint_config": attr.label(
            doc = "eslint config (js_library).",
            configurable = False,
            mandatory = True,
        ),
        "srcs": attr.label_list(
            doc = "Sources to lint.",
            allow_empty = False,
            allow_files = True,
        ),
        "tags": attr.string_list(
            doc = "tags, propagated to all targets",
            configurable = False,
        ),
        "testonly": attr.bool(
            doc = "Testonly flag",
            configurable = False,
        ),
        "tsconfig": attr.label(
            doc = "tsconfig of the sources.",
            configurable = False,
            mandatory = True,
        ),
    },
    implementation = _eslint_impl,
)
