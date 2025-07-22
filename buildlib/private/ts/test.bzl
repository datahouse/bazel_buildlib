"""Datahouse specific rules for typescript code."""

load("@aspect_rules_js//js:providers.bzl", "JsInfo")
load("//private:npm_js_binary.bzl", "npm_js_test")
load(":library.bzl", "ts_library")

def _jest_test_impl(name, data, deps, env, tags, ts_sources, uses_dom, visibility):
    if uses_dom:
        env_deps = [
            "//:node_modules/react-app-polyfill",
            "//:node_modules/jest-environment-jsdom",
            "//:node_modules/identity-obj-proxy",
        ]
    else:
        env_deps = []

    jest_config = Label("//private/ts/jest-config:config")

    # Clone env so we can safely modify it (so we can configure the config 🤯).
    env = dict(env)
    env.update(
        DH_BUILDLIB_TS_TEST_ENABLE_DOM = str(int(uses_dom)),
        DH_BUILDLIB_TS_TEST_JEST_CONFIG_PATH = "$(rootpath %s)" % jest_config,
    )

    npm_js_test(
        name = name,
        node_module = "jest",
        entry_point = "bin/jest.js",
        # We pass srcs to js_test as well so it can resolve source maps and show error context.
        # The customized testRegex ensures jest will not try to execute them as test.
        data = [
            "//:node_modules/@babel/plugin-transform-modules-commonjs",
            Label("//private/ts/jest-config:deps"),
            jest_config,
        ] + deps + env_deps + data + ts_sources,
        tags = tags,
        env = env,
        # node_fs patching seems to badly interact with how jest loads dependencies.
        # the jest 30.x upgrade surfaced this (see #1316).
        patch_node_fs = False,
        fixed_args = [
            "--no-cache",
            "--ci",
            "--colors",
            "--config",
            "$(rootpath %s)" % jest_config,
        ],
        visibility = visibility,
    )

_jest_test = macro(
    implementation = _jest_test_impl,
    attrs = {
        "data": attr.label_list(),
        "deps": attr.label_list(providers = [JsInfo]),
        "env": attr.string_dict(
            default = {},
            configurable = False,
        ),
        "tags": attr.string_list(configurable = False),
        "ts_sources": attr.label_list(allow_files = True),
        "uses_dom": attr.bool(configurable = False),
    },
)

def ts_test(
        name,
        srcs,
        deps = [],
        data = [],
        uses_dom = False,
        env = None,
        tags = [],
        tsc_repository = "@npm_typescript"):
    """Typescript test (run with jest)

    Example: [`@examples//shared-lib/test`](../../examples/shared-lib/test/BUILD.bazel#:~:text=name%20%3D%20%22test%22%2C)

    Args:
      name: name of the rule
      srcs: tests to compile and run. Typically a glob: `glob(["**/*.ts", "**/*.tsx"])`.
      deps: dependencies (other ts_library or npm dependencies)
      data: required runtime data (e.g. csv files)
      uses_dom: Whether the tests (or the code under test) requires a DOM.
      env: Additional environment variables to be made available in the test
        (subject to `$(location)` and make variable expansion).
      tags: tags, propagated to all targets
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
        tags = tags,
        tsc_repository = tsc_repository,
    )

    _jest_test(
        name = name,
        ts_sources = srcs,
        deps = [name + ".compiled"],
        uses_dom = uses_dom,
        # Conceputally it might make more sense to pass `data` to the `ts_library` above.
        # However, that will make location expansion in `env` fail.
        # Therefore, we only pass it here.
        data = data,
        tags = tags,
        env = env,
    )
