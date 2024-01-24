module.exports = {
  env: {
    browser: true,
    es2021: true,
  },
  extends: [
    "airbnb",
    "airbnb/hooks",
    "airbnb-typescript",
    "plugin:@typescript-eslint/recommended-type-checked",
    "plugin:react/jsx-runtime",
    "prettier",
  ],
  parser: "@typescript-eslint/parser",
  parserOptions: {
    ecmaVersion: "latest",
    sourceType: "module",
    project: "**/tsconfig.json",
  },
  plugins: ["@typescript-eslint"],
  reportUnusedDisableDirectives: true,
  overrides: [
    // Config for tests only.
    {
      files: ["*.test.ts", "*.test.tsx"],
      plugins: ["jest"],
      extends: "plugin:jest/recommended",

      rules: {
        // Mock-aware unbound method check.
        "@typescript-eslint/unbound-method": "off",
        "jest/unbound-method": "error",
      },
    },
  ],
  rules: {
    // Allow everything in template expressions (not only strings).
    //
    // Otherwise, it is not clear how to write debug error messages / log
    // statements.
    //
    // We might reconsider this at a future point in time when we have more
    // principled ways of doing this (e.g. a logging library that takes varargs).
    "@typescript-eslint/restrict-template-expressions": "off",

    // Disable all typescript-eslint rules that are affected by imprecise types.
    //
    // It seems that typescript-eslint is not as powerful as tsc when
    // determining types: "complex" types (e.g. Map<string, string> or a
    // PrismaClient extension) sometimes get simplified to any.
    //
    // An example upstream report of this:
    // https://github.com/typescript-eslint/typescript-eslint/issues/3856
    //
    // As a result, the rules below cause false alerts (all of them are rules
    // we'd actually want to enable). So until this is fixed upstream, we
    // unfortunately need to disable them to avoid unnecessary noise.
    "@typescript-eslint/no-unsafe-assignment": "off",
    "@typescript-eslint/no-unsafe-argument": "off",
    "@typescript-eslint/no-unsafe-call": "off",
    "@typescript-eslint/no-unsafe-member-access": "off",
    "@typescript-eslint/no-unsafe-return": "off",
    "@typescript-eslint/no-redundant-type-constituents": "off",

    // class-methods-use-this is too noisy:
    // Both type-graphql and tsoa use classes as encapsulation for logic, but
    // this check assumes they are (mainly) used as encapsulation of data.
    //
    // For our use case (type-graphql and tsoa) it is extremely common (and
    // correct) to have methods that do not refer to `this` whatsoever.
    //
    // Therefore, we disable the linter check to avoid noise.
    "class-methods-use-this": "off",

    // Do not check extraneous dependencies:
    // The bazel setup already does this with the combination of:
    // - pnpm style layout (cannot include transitive dependencies).
    // - normal bazel dependencies (cannot include undeclared packages).
    //
    // The check adds unnecessary noise for sythesized node modules
    // (notably for translate_esm_to_cjs).
    "import/no-extraneous-dependencies": "off",

    // Allow modules with a single non-default export.
    //
    // - Both type-graphql and tsoa require us to do this (export a named class).
    // - The check in any mode is based on the somewhat flawed premise that the
    //   number of module exports will remain constant. This makes it harder /
    //   more noisy to build up a module gradually.
    "import/prefer-default-export": "off",

    // Require file extensions in imports
    //
    // This is to ensure compatibility with the Node.js ESM loader (which
    // requires extensions).
    //
    // Whether and if we can move to that loader is unclear. However,
    // explicit file extensions are the least common denominator between the
    // loaders so this will ensure better forward compatibility.
    "import/extensions": ["error", "ignorePackages"],

    // Allow void to ignore floating promises.
    //
    // In react code, we often rely on the react runtime to deal with the result
    // of an operation (through hooks). In these scenarios we do not care about
    // the promises returned by the operations.
    //
    // However, eslint will (correctly) flag these promises (and suggest we
    // ignore using void). To allow this, we use more specific void operator
    // checking: Allow in general, disallow when it doesn't ignore a value.
    //
    // The use of the void operator for this purpose (rather than, say, an
    // `.ignorePromise()` method) is unfortunate.
    // That being said, at the time of writing, being consistent with what the
    // eslint checks recommend was deemed more important.
    "@typescript-eslint/no-meaningless-void-operator": [
      "error",
      { checkNever: true },
    ],
    "no-void": "off",

    // we need await inside loops because sometimes we cannot list promises
    "no-await-in-loop": "off",
    "no-restricted-syntax": [
      "error",
      {
        selector: "ForInStatement",
        message: "Use the more modern `for ... of` instead of `for ... in`.",
      },
      {
        selector: "LabeledStatement",
        message:
          "Do not use labeled statements. Refactor control flow if necessary.",
      },
      {
        selector: "WithStatement",
        message: "Do not use `with`, it is deprecated (and misleading).",
      },
      {
        selector: "TSEnumDeclaration",
        message:
          'Do not use enums, use unions with constant types instead (e.g. `type X = "FOO" | "BAR"`)',
      },
      {
        // Disallow jest.mock. Replacing modules implicitly is not a good idea:
        // It'll make it intractable what is actually affected by the replacement.
        selector: 'MemberExpression[object.name="jest"][property.name="mock"]',
        message:
          "Do not use jest.mock, use explicit dependency injection instead.",
      },
    ],
    /* no-param-reassign disallows props by default which misses
    the point of the original issue it was attempting to fix:
    Reassigning function parameters changes the arguments "array".
    Of course this is a non-issue for property assignments, since this
    will mutate the objects referenced by the parameters and not the
    parameters themselves.*/
    "no-param-reassign": ["error", { props: false }],

    // Allow dangling underscores.
    //
    // Prisma uses them for aggregations, so we use them heavily:
    // https://www.prisma.io/docs/concepts/components/prisma-client/aggregation-grouping-summarizing
    //
    // The argument of this preventing use of members "hinted" to be private is
    // very weak thanks to type defintions.
    "no-underscore-dangle": "off",
  },
};
