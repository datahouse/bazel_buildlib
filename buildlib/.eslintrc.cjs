module.exports = {
  root: true,
  extends: ["./bazel-bin/eslintrc.dh-defaults.cjs"],
  rules: {
    // basically all JS code in this workspace are CLI tools.
    // console log is OK for these.
    "no-console": "off",
  },
};
