import * as extendedMatchers from "jest-extended";
import { checkEslintConfig } from "../src/eslintConfigProblems.js";

expect.extend(extendedMatchers);

describe("checkEslintConfig", () => {
  it("returns no problems when using required config structure", () => {
    const source = `
      import { defineConfig } from "eslint/config";
      import dhDefaults from "./bazel-bin/dhDefaults.eslint.config.js";

      export default defineConfig([dhDefaults]);
    `;
    expect(checkEslintConfig(source)).toBeNull();
  });

  it("returns no problems when using a default re-export", () => {
    const source = `
      export { default } from "./bazel-bin/dhDefaults.eslint.config.js"
    `;
    expect(checkEslintConfig(source)).toBeNull();
  });

  it("returns a problem when dhDefaults is other than './bazel-bin/dhDefaults.eslint.config.js'", () => {
    const source = `
      import { defineConfig } from "eslint/config";
      const dhDefaults = {
        rules: {
          "no-continue": "off",
        }
      }
      export default defineConfig([dhDefaults]);
    `;
    expect(checkEslintConfig(source)).not.toBeNull();
  });

  it("returns a problem when the default export does not use defineConfig([dhDefaults, ...])", () => {
    const source = `
      import { defineConfig } from "eslint/config";

      export default defineConfig([]);
    `;
    expect(checkEslintConfig(source)).not.toBeNull();
  });

  it("returns a problem when the default export uses a different first array element", () => {
    const source = `
      import { defineConfig } from "eslint/config";
      import dhDefaults from "./bazel-bin/dhDefaults.eslint.config.js";
      const other = {};

      export default defineConfig([other, dhDefaults]);
    `;
    expect(checkEslintConfig(source)).not.toBeNull();
  });

  it("returns a problem when defineConfig is other than 'eslint/config'", () => {
    const source = `
      import dhDefaults from "./bazel-bin/dhDefaults.eslint.config.js";
      function defineConfig(cfgs) {
        return cfgs
      }
      export default defineConfig([dhDefaults]);
    `;
    expect(checkEslintConfig(source)).not.toBeNull();
  });

  it("returns a problem when defineConfig is aliased", () => {
    const source = `
      import { defineConfig as createConfig } from "eslint/config";
      import dhDefaults from "./bazel-bin/dhDefaults.eslint.config.js";

      export default createConfig([dhDefaults]);
    `;
    expect(checkEslintConfig(source)).not.toBeNull();
  });

  it("returns a problem when dhDefaults is aliased", () => {
    const source = `
      import { defineConfig } from "eslint/config";
      import myDefaults from "./bazel-bin/dhDefaults.eslint.config.js";

      export default createConfig([myDefaults]);
    `;
    expect(checkEslintConfig(source)).not.toBeNull();
  });

  it("returns a problem when using an aliased default re-export", () => {
    const source = `
      export { default as myDefault } from "./bazel-bin/dhDefaults.eslint.config.js"
    `;
    expect(checkEslintConfig(source)).not.toBeNull();
  });
});
