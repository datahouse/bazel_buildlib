// Babel config for babel-jest (see test.bzl). Order matters: this plugin
// (replaces leftover `import.meta` with `{}`) must run before commonjs and after
// babel-plugin-transform-import-meta, which rewrites the well-known props
// (import.meta.url etc.).
type PluginObj = import("@babel/core").PluginObj;

const transformResidualImportMeta: PluginObj = {
  name: "transform-residual-import-meta",
  visitor: {
    MetaProperty(path) {
      if (path.node.meta.name === "import") {
        path.replaceWith({ type: "ObjectExpression", properties: [] });
      }
    },
  },
};

module.exports = {
  env: {
    test: {
      plugins: [
        "babel-plugin-transform-import-meta",
        transformResidualImportMeta,
        "@babel/plugin-transform-modules-commonjs",
      ],
    },
  },
};
