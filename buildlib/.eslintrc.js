module.exports = {
  extends: ["./bazel-bin/eslintrc.dh-defaults.js"],
  rules: {
    // basically all JS code in this workspace are CLI tools.
    // console log is OK for these.
    "no-console": "off",
  },
};
