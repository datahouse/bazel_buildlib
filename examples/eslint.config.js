import { defineConfig, globalIgnores } from "eslint/config";

import dhDefaults from "./bazel-bin/dhDefaults.eslint.config.js";

export default defineConfig([
  dhDefaults,
  // Files / patterns to ignore.
  // Typically, this is only for generated files. However, it can also be
  // useful, for example, for extrenally provided files that we track in our
  // repositories (in case they follow different code standards).
  globalIgnores([
    // generated
    "api/clients/gravatar-schema.ts",
    "frontend/gql/**",
  ]),
  {
    // Project specific linter settings go here.
    // See buildlib/eslint.config.cjs for an example.
    //
    // If you adjust this, please file an it-bazel issue to check whether it makes
    // sense to enable / disable the setting at a global level.
  },
]);
