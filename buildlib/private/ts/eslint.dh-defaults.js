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

    // Disable all rules that warn about unsafe any assignments.
    //
    // While we'd really want these to catch any's that sneak in from libraries,
    // they unfortunately seem to be broken when "complex" types (e.g.
    // Map<string, string> or a PrismaClient extension) are pulled in from other
    // compilation units.
    //
    // So until we can fix that issue, these will cause more noise than good.
    "@typescript-eslint/no-unsafe-assignment": "off",
    "@typescript-eslint/no-unsafe-argument": "off",
    "@typescript-eslint/no-unsafe-call": "off",
    "@typescript-eslint/no-unsafe-member-access": "off",
    "@typescript-eslint/no-unsafe-return": "off",

    // class-methods-use-this is too noisy:
    // Both type-graphql and tsoa use classes as encapsulation for logic, but
    // this check assumes they are (mainly) used as encapsulation of data.
    //
    // For our use case (type-graphql and tsoa) it is extremely common (and
    // correct) to have methods that do not refer to `this` whatsoever.
    //
    // Therefore, we disable the linter check to avoid noise.
    "class-methods-use-this": "off",
    // Allow modules with a single non-default export.
    //
    // - Both type-graphql and tsoa require us to do this (export a named class).
    // - The check in any mode is based on the somewhat flawed premise that the
    //   number of module exports will remain constant. This makes it harder /
    //   more noisy to build up a module gradually.
    "import/prefer-default-export": "off",
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
  },
};
