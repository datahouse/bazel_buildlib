import { cwd } from "node:process";
import { dirname, join } from "node:path";

import type { Config } from "jest";

const dom = process.env.DH_BUILDLIB_TS_TEST_ENABLE_DOM === "1";
const configPath = process.env.DH_BUILDLIB_TS_TEST_JEST_CONFIG_PATH;
const esmDepsEnv = process.env.DH_BUILDLIB_TS_TEST_ESM_NODE_MODULES;
// aspect_rules_js rewrites scoped packages: @scope/pkg -> @scope+pkg@version
// For unscoped packages: pkg -> pkg@version
// See _package_store_name in:
// https://github.com/aspect-build/rules_js/blob/main/npm/private/utils.bzl
// We need to match these paths in the transformIgnorePatterns regex.
const extraEsmDeps: string[] = esmDepsEnv!
  .split(",")
  .filter(Boolean)
  .map((d: string) => RegExp.escape(`${d.replaceAll("/", "+")}@`));
const enableJestEsm = process.env.DH_BUILDLIB_TS_TEST_ENABLE_ESM === "1";

// The jest config lies somewhere completely different than where the tests lie.
const rootDir = cwd();
const configDir = join(cwd(), dirname(configPath!));

const buildlibConfig = (name: string) => join(configDir, name);

const transform: Config["transform"] = !enableJestEsm
  ? {
      // Invoke babel-jest for all JS sources.
      // We need this for:
      // - ESM support: Jest does not support ESM yet, so we transpile the
      //   sources on the fly (we inject a custom babel config for this).
      //   We should remove this, once Jest supports ESM:
      //   https://jestjs.io/docs/ecmascript-modules
      // - Module mocks, see #247
      //   https://jestjs.io/docs/configuration#transform-objectstring-pathtotransformer--pathtotransformer-object
      "\\.[mc]?[jt]sx?$": [
        "babel-jest",
        { extends: buildlibConfig("babel.config.cjs") },
      ],
    }
  : {
      // No transformation necessary.
      // Module mocks do not work anyways under ESM:
      // https://jestjs.io/docs/ecmascript-modules#module-mocking-in-esm
    };

const moduleNameMapper: Config["moduleNameMapper"] = {};

if (dom) {
  // Transform imports of assets (svg, etc.)
  // The patterns are copied from ejected CRA config.
  transform["^(?!.*\\.(js|jsx|mjs|cjs|ts|tsx|css|json)$)"] =
    buildlibConfig("FileTransform.cjs");

  // Mock imported CSS.
  // https://jestjs.io/docs/webpack#mocking-css-modules
  moduleNameMapper["\\.css$"] = "identity-obj-proxy";
}

const config: Config = {
  rootDir,
  haste: { enableSymlinks: true },
  watchman: false,
  moduleNameMapper,
  // Polyfills for jsdom. Technically only for react (not all DOM) but in
  // practice the distinction unlikely matters.
  setupFiles: dom ? ["react-app-polyfill/jsdom"] : [],
  testEnvironment: dom ? "jsdom" : "node",
  testRegex: [
    // Exclude ts files: We pass them to jest as well so it can show
    // error context resolved via source maps. However, we do not want
    // jest to execute them as tests as well.
    "(\\.|/)test\\.[mc]?jsx?$",
  ],
  transform,
};

if (!enableJestEsm) {
  // Selectively CJS transform known node modules that publish only for ESM.
  //
  // We use a negative lookahead regex for this as suggested in the doc:
  // https://jestjs.io/docs/configuration#transformignorepatterns-arraystring
  //
  // Note that the selectivity is crucial: At the time of writing,
  // transforming all node modules on //frontend/test
  // increases the test runtime from 10s to 70s.
  config.transformIgnorePatterns = [
    extraEsmDeps.length > 0
      ? `node_modules/\\.aspect_rules_js/(?!${extraEsmDeps.join("|")})`
      : `node_modules/\\.aspect_rules_js/`,
  ];
}

export default config;
