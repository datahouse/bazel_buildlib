import { cwd } from "node:process";
import { dirname, join } from "node:path";

import type { Config } from "jest";

const dom = process.env.DH_BUILDLIB_TS_TEST_ENABLE_DOM === "1";
const configPath = process.env.DH_BUILDLIB_TS_TEST_JEST_CONFIG_PATH;

// The jest config lies somewhere completely different than where the tests lie.
const rootDir = cwd();
const configDir = join(cwd(), dirname(configPath!));

const buildlibConfig = (name: string) => join(configDir, name);

const transform: Config["transform"] = {
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
  // Selectively CJS transform known node modules that publish only for ESM.
  //
  // We use a negative lookahead regex for this as suggested in the doc:
  // https://jestjs.io/docs/configuration#transformignorepatterns-arraystring
  //
  // Note that the selectivity is crucial: At the time of writing,
  // transforming all node modules on //frontend/test
  // increases the test runtime from 10s to 70s.
  transformIgnorePatterns: [
    "node_modules/\\.aspect_rules_js/(?!graphql-upload@|react-error-boundary@)",
  ],
};

export default config;
