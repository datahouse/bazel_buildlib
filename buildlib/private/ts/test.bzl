"""Datahouse specific rules for typescript code."""

load("@aspect_rules_js//js:providers.bzl", "JsInfo")
load("//private:npm_js_binary.bzl", "npm_js_test")
load(":library.bzl", "ts_library")
load(":npm_name_check.bzl", "check_is_well_behaved_npm_name")

def _jest_test_impl(name, data, deps, env_inherit, env, esm_node_modules, tags, ts_sources, uses_dom, enable_jest_esm, visibility):
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
        DH_BUILDLIB_TS_TEST_ESM_NODE_MODULES = ",".join(esm_node_modules),
        DH_BUILDLIB_TS_TEST_ENABLE_ESM = str(int(enable_jest_esm)),
    )

    # We pass srcs to js_test as well so it can resolve source maps and show error context.
    # The customized testRegex ensures jest will not try to execute them as test.
    data = [
        Label("//private/ts/jest-config:deps"),
        jest_config,
    ] + deps + env_deps + data + ts_sources

    if not enable_jest_esm:
        # Note: Do not use `append` so `data` remains configurable (as in: can be a `select`).
        data = data + [
            Label("//:node_modules/@babel/plugin-transform-modules-commonjs"),
            Label("//:node_modules/babel-plugin-transform-import-meta"),
        ]

    npm_js_test(
        name = name,
        node_module = "jest",
        entry_point = "bin/jest.js",
        data = data,
        tags = tags,
        env_inherit = env_inherit,
        env = env,
        node_options = ["--experimental-vm-modules"] if enable_jest_esm else [],
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
        "enable_jest_esm": attr.bool(configurable = False),
        "env": attr.string_dict(
            default = {},
            configurable = False,
        ),
        "env_inherit": attr.string_list(default = []),
        "esm_node_modules": attr.string_list(configurable = False),
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
        esm_node_modules = ["graphql-upload", "react-error-boundary"],
        env = None,
        tags = [],
        enable_jest_esm = False,
        tsc_repository = "@npm_typescript"):
    """Typescript test (run with jest)

    Example: [`@examples//shared-lib/test`](../../examples/shared-lib/test/BUILD.bazel#:~:text=name%20%3D%20%22test%22%2C)

    Args:
      name: name of the rule
      srcs: tests to compile and run. Typically a glob: `glob(["**/*.ts", "**/*.tsx"])`.
      deps: dependencies (other ts_library or npm dependencies)
      data: required runtime data (e.g. csv files)
      uses_dom: Whether the tests (or the code under test) requires a DOM.
      esm_node_modules: List of npm package names that publish only ESM (no CommonJS fallback).
        Jest will Babel-transform these packages instead of skipping them.
        Names must be lowercase, may contain hyphens/dots/underscores, and must
        not exceed 120 characters. Scoped packages (@scope/pkg) are supported.
        Example: `esm_node_modules = ["some-esm-pkg"]`.
      env: Additional environment variables to be made available in the test
        ([subject to 'Make variable' substitution](https://bazel.build/reference/be/make-variables)).
      tags: Tags propagated to all targets. In addition to standard Bazel keywords,
        the following keywords have special meaning:
        - requires-docker: Enables Docker access for the test. Automatically adds
          `requires-network` and inherits the `DOCKER_HOST` environment variable,
          allowing connection to an external Docker daemon.
      enable_jest_esm: EXPERIMENTAL Enable [Jest ESM support](https://jestjs.io/docs/ecmascript-modules)
        Note that [module mocking is not supported](https://jestjs.io/docs/ecmascript-modules#module-mocking-in-esm)
      tsc_repository: which typescript bazel repository to use
        (most likely you will not need this option).
    """
    for dep in esm_node_modules:
        check_is_well_behaved_npm_name(dep)

    env_inherit = []
    if "requires-docker" in tags:
        if "requires-network" not in tags:
            # The "requires-docker" tag is preserved for queryability
            tags = tags + ["requires-network"]
        env_inherit = ["DOCKER_HOST"]

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
        esm_node_modules = esm_node_modules,
        # Conceputally it might make more sense to pass `data` to the `ts_library` above.
        # However, that will make location expansion in `env` fail.
        # Therefore, we only pass it here.
        data = data,
        tags = tags,
        env = env,
        env_inherit = env_inherit,
        enable_jest_esm = enable_jest_esm,
    )
