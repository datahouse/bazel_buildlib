"""Datahouse specific rules for typescript code."""

load("@aspect_bazel_lib//lib:paths.bzl", "relative_file")
load(":library.bzl", "ts_library")
load(":npm_js_binary.bzl", "npm_js_test")

def _jest_config_impl(ctx):
    dom = ctx.attr.uses_dom

    cfg_path = ctx.outputs.out.short_path

    transform = {
        # Default. Required for module mocks, see #247
        # https://jestjs.io/docs/configuration#transform-objectstring-pathtotransformer--pathtotransformer-object
        "\\.[jt]sx?$": "babel-jest",
    }
    module_name_mapper = {}

    if dom:
        # Transform imports of assets (svg, etc.)
        # The patterns are copied from ejected CRA config.
        transform["^(?!.*\\.(js|jsx|mjs|cjs|ts|tsx|css|json)$)"] = relative_file(ctx.file.file_transform.short_path, cfg_path)

        # Mock imported CSS.
        # https://jestjs.io/docs/webpack#mocking-css-modules
        module_name_mapper["\\.css$"] = "identity-obj-proxy"

    cfg = {
        "haste": {"enableSymlinks": True},
        "moduleNameMapper": module_name_mapper,
        # Polyfills for jsdom. Technically only for react (not all DOM) but in
        # practice the distinction unlikely matters.
        "setupFiles": ["react-app-polyfill/jsdom"] if dom else [],
        "testEnvironment": "jsdom" if dom else "node",
        "transform": transform,
    }

    ctx.actions.write(ctx.outputs.out, json.encode(cfg))

_jest_config = rule(
    implementation = _jest_config_impl,
    attrs = {
        "file_transform": attr.label(allow_single_file = [".js"]),
        "out": attr.output(),
        "uses_dom": attr.bool(),
    },
)

def ts_test(name, srcs = None, deps = [], data = [], uses_dom = False, tags = None):
    """Typescript test (run with jest)

    Example: [`@examples//shared-lib/test`](../../examples/shared-lib/test/BUILD.bazel#:~:text=name%20%3D%20%22test%22%2C)

    Args:
      name: name of the rule
      srcs: tests to compile and run. Defaults to `ts_default_srcs()`.
      deps: dependencies (other ts_library or npm dependencies)
      data: required runtime data (e.g. csv files)
      uses_dom: Whether the tests (or the code under test) requires a DOM.
      tags: tags (propagated to the test rule)
    """

    ts_library(
        name = name + ".compiled",
        srcs = srcs,
        data = data,
        uses_dom = uses_dom,
        deps = [
            "//:node_modules/@types/jest",
        ] + deps,
        testonly = True,
    )

    _config_name = name + ".jest.config.json"

    _jest_config(
        name = name + ".jest.config",
        uses_dom = uses_dom,
        out = _config_name,
        file_transform = Label("//private/ts/src:FileTransform.js"),
        testonly = True,
    )

    if uses_dom:
        env_deps = [
            "//:node_modules/react-app-polyfill",
            "//:node_modules/jest-environment-jsdom",
            "//:node_modules/identity-obj-proxy",
            Label("//private/ts/src:FileTransform.js"),
        ]
    else:
        env_deps = []

    # A note about output module configuration when uses_dom is true:
    #
    # It seems that create react app feeds CommonJS (not ES modules) to jest,
    # we replicate this behavior for now.
    npm_js_test(
        name = name,
        node_module = "jest",
        entry_point = "bin/jest.js",
        data = [
            name + ".compiled",
            _config_name,
        ] + env_deps,
        tags = tags,
        args = [
            "--no-cache",
            "--no-watchman",
            "--ci",
            "--colors",
            "--config",
            "$(rootpath %s)" % _config_name,
        ],
    )
