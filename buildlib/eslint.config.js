import { defineConfig } from "eslint/config";

import dhDefaults from "./bazel-bin/dhDefaults.eslint.config.js";

export default defineConfig([
  dhDefaults,
  {
    rules: {
      // basically all JS code in this workspace are CLI tools.
      // console log is OK for these.
      "no-console": "off",
    },
  },
]);
