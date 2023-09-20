"""Custom js_binary rule."""

load("@aspect_rules_js//js:libs.bzl", "js_binary_lib")
load("@bazel_skylib//lib:dicts.bzl", "dicts")

def _commonjs_transition_impl(_settings, _attr):
    return {
        "//private/ts:module": "commonjs",
    }

commonjs_transition = transition(
    implementation = _commonjs_transition_impl,
    inputs = [],
    outputs = [
        "//private/ts:module",
    ],
)

_js_binary = rule(
    implementation = js_binary_lib.implementation,
    attrs = dicts.add(js_binary_lib.attrs, {
        "_allowlist_function_transition": attr.label(
            default = "@bazel_tools//tools/allowlists/function_transition_allowlist",
        ),
    }),
    executable = True,
    toolchains = js_binary_lib.toolchains,
    cfg = commonjs_transition,
)

def js_binary(**kwargs):
    """js_binary rule that transitions its sources to CommonJS modules.

    Otherwise equivalent to [js_binary in rules_js](https://github.com/aspect-build/rules_js/blob/main/docs/js_binary.md).
    If in doubt, use this over the one in rules_js.

    Example: [`@examples//prisma/seed`](../../examples/prisma/seed/BUILD.bazel#:~:text=name%20%3D%20%22seed%22%2C)

    Args:
      **kwargs: Keyword arguments directly forwarded to rules_js' js_binary.
    """

    _js_binary(
        enable_runfiles = select({
            "@aspect_rules_js//js:enable_runfiles": True,
            "//conditions:default": False,
        }),
        unresolved_symlinks_enabled = select({
            "@aspect_rules_js//js:allow_unresolved_symlinks": True,
            "//conditions:default": False,
        }),
        **kwargs
    )

_js_test = rule(
    implementation = js_binary_lib.implementation,
    attrs = dicts.add(js_binary_lib.attrs, {
        "_allowlist_function_transition": attr.label(
            default = "@bazel_tools//tools/allowlists/function_transition_allowlist",
        ),
    }),
    test = True,
    toolchains = js_binary_lib.toolchains,
    cfg = commonjs_transition,
)

def js_test(**kwargs):
    """js_test rule that transitions its sources to CommonJS modules.

    Otherwise equivalent to [js_test in rules_js](https://github.com/aspect-build/rules_js/blob/main/docs/js_binary.md).
    If in doubt, use this over the one in rules_js.

    Args:
      **kwargs: Keyword arguments directly forwarded to rules_js' js_test.
    """

    _js_test(
        enable_runfiles = select({
            "@aspect_rules_js//js:enable_runfiles": True,
            "//conditions:default": False,
        }),
        unresolved_symlinks_enabled = select({
            "@aspect_rules_js//js:allow_unresolved_symlinks": True,
            "//conditions:default": False,
        }),
        **kwargs
    )
