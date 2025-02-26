"""Datahouse specific rules for typescript code."""

load("@aspect_bazel_lib//lib:paths.bzl", "relative_file")
load("@bazel_skylib//rules:copy_file.bzl", "copy_file")
load("//private:npm_js_binary.bzl", "npm_js_test")
load(":library.bzl", "ts_library")

def _jest_config_impl(ctx):
    dom = ctx.attr.uses_dom

    cfg_path = ctx.outputs.out.short_path

    transform = {
        # Invoke babel-jest for all JS sources.
        # We need this for:
        # - ESM support: Jest does not support ESM yet, so we transpile the
        #   sources on the fly (we inject a custom babel config for this).
        #   We should remove this, once Jest supports ESM:
        #   https://jestjs.io/docs/ecmascript-modules
        # - Module mocks, see #247
        #   https://jestjs.io/docs/configuration#transform-objectstring-pathtotransformer--pathtotransformer-object
        "\\.[mc]?[jt]sx?$": "babel-jest",
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
        # Selectively CJS transform known node modules that publish only for ESM.
        #
        # We use a negative lookahead regex for this as suggested in the doc:
        # https://jestjs.io/docs/configuration#transformignorepatterns-arraystring
        #
        # Note that the selectivity is crucial: At the time of writing,
        # transforming all node modules on //frontend/test
        # increases the test runtime from 10s to 70s.
        "transformIgnorePatterns": [
            "node_modules/\\.aspect_rules_js/(?!graphql-upload@)",
        ],
    }

    ctx.actions.write(ctx.outputs.out, json.encode(cfg))

_jest_config = rule(
    implementation = _jest_config_impl,
    attrs = {
        "file_transform": attr.label(allow_single_file = [".cjs"]),
        "out": attr.output(),
        "uses_dom": attr.bool(),
    },
)

def ts_test(
        name,
        srcs = None,
        deps = [],
        data = [],
        uses_dom = False,
        env = None,
        tags = None,
        tsc_repository = "@npm_typescript"):
    """Typescript test (run with jest)

    Example: [`@examples//shared-lib/test`](../../examples/shared-lib/test/BUILD.bazel#:~:text=name%20%3D%20%22test%22%2C)

    Args:
      name: name of the rule
      srcs: tests to compile and run. Defaults to `ts_default_srcs()`.
      deps: dependencies (other ts_library or npm dependencies)
      data: required runtime data (e.g. csv files)
      uses_dom: Whether the tests (or the code under test) requires a DOM.
      env: Additional environment variables to be made available in the test
        (subject to `$(location)` and make variable expansion).
      tags: tags (propagated to the test rule)
      tsc_repository: which typescript bazel repository to use
        (most likely you will not need this option).
    """

    ts_library(
        name = name + ".compiled",
        srcs = srcs,
        uses_dom = uses_dom,
        deps = [
            "//:node_modules/@types/jest",
        ] + deps,
        testonly = True,
        tsc_repository = tsc_repository,
    )

    _config_name = name + ".jest.config.json"

    _jest_config(
        name = name + ".jest.config",
        uses_dom = uses_dom,
        out = _config_name,
        file_transform = Label("//private/ts:file_transform"),
        testonly = True,
    )

    # Babel config (implicitly read by `babel-jest`).
    copy_file(
        name = name + ".babel.config.cjs",
        src = Label(":babel.config.cjs"),
        out = "babel.config.cjs",
    )

    if uses_dom:
        env_deps = [
            "//:node_modules/react-app-polyfill",
            "//:node_modules/jest-environment-jsdom",
            "//:node_modules/identity-obj-proxy",
            Label("//private/ts:file_transform"),
        ]
    else:
        env_deps = []

    npm_js_test(
        name = name,
        node_module = "jest",
        entry_point = "bin/jest.js",
        # Conceputally it might make more sense to pass `data` to the `ts_library` above.
        # However, that will make location expansion in `env` fail.
        # Therefore, we only pass it here.
        data = [
            name + ".compiled",
            _config_name,
            name + ".babel.config.cjs",
            "//:node_modules/@babel/plugin-transform-modules-commonjs",
        ] + env_deps + data,
        tags = tags,
        env = env,
        args = [
            "--no-cache",
            "--no-watchman",
            "--ci",
            "--colors",
            "--config",
            "$(rootpath %s)" % _config_name,
        ],
    )
