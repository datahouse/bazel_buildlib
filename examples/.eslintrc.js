module.exports = {
  extends: "./bazel-bin/eslintrc.dh-defaults.js",

  // Files / patterns to ignore.
  // Typically, this is only for generated files. However, it can also be
  // useful, for example, for extrenally provided files that we track in our
  // repositories (in case they follow different code standards).
  ignorePatterns: [
    "frontend/src/gql/**", // generated
  ],

  // Project specific linter settings go here.
  // See buildlib/.eslintrc.js for an example.
  //
  // If you adjust this, please file an it-bazel issue to check whether it makes
  // sense to enable / disable the setting at a global level.
};
