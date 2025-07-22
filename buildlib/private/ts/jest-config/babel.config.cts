// Babel config for babel-jest
// See the comment in test.bzl for why we have this.
module.exports = {
  env: {
    test: {
      plugins: ["@babel/plugin-transform-modules-commonjs"],
    },
  },
};
