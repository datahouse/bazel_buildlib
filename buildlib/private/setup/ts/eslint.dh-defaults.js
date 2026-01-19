import { defineConfig } from "eslint/config";

import globals from "globals";
import eslint from "@eslint/js";
import tseslint from "typescript-eslint";
import jest from "eslint-plugin-jest";
import prettier from "eslint-config-prettier";
import react from "eslint-plugin-react";

import { FlatCompat } from "@eslint/eslintrc";

const rules = {
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
  // no-param-reassign disallows props by default which misses
  // the point of the original issue it was attempting to fix:
  // Reassigning function parameters changes the arguments "array".
  // Of course this is a non-issue for property assignments, since this
  // will mutate the objects referenced by the parameters and not the
  // parameters themselves.
  "no-param-reassign": ["error", { props: false }],

  // Allow dangling underscores.
  //
  // Prisma uses them for aggregations, so we use them heavily:
  // https://www.prisma.io/docs/concepts/components/prisma-client/aggregation-grouping-summarizing
  //
  // The argument of this preventing use of members "hinted" to be private is
  // very weak thanks to type defintions.
  "no-underscore-dangle": "off",

  // Allow nested ternary operators
  //
  // This helps to provide a concise and clear way to express conditional logic, especially
  // when dealing with simple conditions (f.e. selecting different components or values
  // based on the state of the react application).
  "no-nested-ternary": "off",

  // Disallow method shorthand syntax
  //
  // The syntax is unexpectedly bivariant which is considered harmful
  // https://www.totaltypescript.com/method-shorthand-syntax-considered-harmful
  "@typescript-eslint/method-signature-style": "error",

  // Enforce javascript default parameters instead of defaultProps for functional components
  //
  // DefaultProps on functional components will be deprecated in the next major release
  // https://github.com/facebook/react/pull/16210
  "react/require-default-props": [
    "error",
    {
      functions: "defaultArguments",
      forbidDefaultForRequired: true,
    },
  ],

  // Should not be used when enabling type checked rules
  // See https://typescript-eslint.io/rules/prefer-promise-reject-errors/#when-not-to-use-it
  "prefer-promise-reject-errors": "off",
  "@typescript-eslint/prefer-promise-reject-errors": "off",

  // Disable no-return-await:
  // - It is deprecated.
  // - It causes false negatives with `await using`.
  "no-return-await": "off",
};

// Compatibility layer for extending from dependencies that do not yet
// support the ESLint 9 flat config. Examples include `airbnb` and `airbnb-typescript`.
// This remains the recommended approach until migration is complete and it is
// auto-generated by the ESLint 9 config migration tool.
// See: https://eslint.org/docs/latest/use/configure/migration-guide#using-eslintrc-configs-in-flat-config
const compat = new FlatCompat({
  baseDirectory: import.meta.dirname,
});

export default defineConfig([
  // In general, we use recommended configs rather than strict or full rule sets.
  // Recommended presets provide reliable, broadly applicable rules without the
  // breaking/frequent changes of full configs or the added noise of stricter ones.
  eslint.configs.recommended,
  compat.extends("airbnb", "airbnb/hooks"),
  tseslint.configs.recommendedTypeChecked,
  {
    extends: [
      react.configs.flat.recommended,
      react.configs.flat["jsx-runtime"],
    ],
    rules: {
      "react/jsx-filename-extension": [
        "error",
        { extensions: [".jsx", ".tsx"] },
      ],
    },
  },
  prettier,
  {
    // Rules and comments carried over from the archived eslint-config-airbnb-typescript
    // See: https://github.com/iamturns/eslint-config-airbnb-typescript/blob/master/lib/shared.js
    rules: {
      // The following rules are enabled in Airbnb config,
      // but are already checked (more thoroughly) by the TypeScript compiler
      // Some of the rules also fail in TypeScript files, for example:
      // https://github.com/typescript-eslint/typescript-eslint/issues/662#issuecomment-507081586
      "valid-typeof": "off",

      // The following rules are enabled in Airbnb config, but are recommended
      // to be disabled within TypeScript projects
      // See: https://github.com/typescript-eslint/typescript-eslint/blob/13583e65f5973da2a7ae8384493c5e00014db51b/docs/linting/TROUBLESHOOTING.md#eslint-plugin-import
      "import/named": "off",
      "import/no-named-as-default-member": "off",

      // Disable `import/no-unresolved` as the TypeScript compiler will catch these errors
      "import/no-unresolved": "off",

      camelcase: "off",
      // The `@typescript-eslint/naming-convention` rule allows `leadingUnderscore` and `trailingUnderscore` settings. However, the existing `no-underscore-dangle` rule already takes care of this.
      "@typescript-eslint/naming-convention": [
        "error",
        // Allow camelCase variables, PascalCase variables, and UPPER_CASE variables
        {
          selector: "variable",
          format: ["camelCase", "PascalCase", "UPPER_CASE"],
        },
        // Allow camelCase functions, and PascalCase functions
        {
          selector: "function",
          format: ["camelCase", "PascalCase"],
        },
        // Airbnb recommends PascalCase for classes, and although Airbnb does not make TypeScript recommendations, we are assuming this rule would similarly apply to anything "type like", including interfaces, type aliases, and enums
        {
          selector: "typeLike",
          format: ["PascalCase"],
        },
      ],

      "default-param-last": "off",
      "@typescript-eslint/default-param-last": "error",

      "dot-notation": "off",
      "@typescript-eslint/dot-notation": "error",

      "no-empty-function": "off",
      "@typescript-eslint/no-empty-function": [
        "error",
        {
          allow: ["arrowFunctions", "functions", "methods"],
        },
      ],

      "no-new-func": "off",

      "no-loop-func": "off",
      "@typescript-eslint/no-loop-func": "error",

      "no-magic-numbers": "off",
      "@typescript-eslint/no-magic-numbers": [
        "off",
        {
          ignore: [],
          ignoreArrayIndexes: true,
          enforceConst: true,
          detectObjects: false,
        },
      ],

      "no-shadow": "off",
      "@typescript-eslint/no-shadow": "error",

      "no-throw-literal": "off",
      "@typescript-eslint/only-throw-error": "error",

      "no-unused-expressions": "off",
      "@typescript-eslint/no-unused-expressions": "error",

      "@typescript-eslint/no-unused-vars": [
        "error",
        { vars: "all", args: "after-used", ignoreRestSiblings: true },
      ],

      "no-use-before-define": "off",
      "@typescript-eslint/no-use-before-define": [
        "error",
        { functions: true, classes: true, variables: true },
      ],

      "no-useless-constructor": "off",
      "@typescript-eslint/no-useless-constructor": "error",
    },
  },
  {
    languageOptions: {
      globals: {
        ...globals.browser,
      },
      parser: tseslint.parser,
      parserOptions: {
        // projectService replaces the old project option; it lets IDEs pick up the correct tsconfig
        // and enables ESLint to lint files outside the main tsconfig.json, with improved monorepo support.
        projectService: {
          allowDefaultProject: [
            "eslint.config.js",
            "bazel-bin/dhDefaults.eslint.config.js",
          ],
        },
      },
    },
    rules,
  },
  {
    // Config for tests only.
    files: ["**/*.test.ts", "**/*.test.tsx"],
    plugins: { jest },
    extends: [jest.configs["flat/recommended"]],
    rules: {
      // Mock-aware unbound method check.
      "@typescript-eslint/unbound-method": "off",
      "jest/unbound-method": "error",
    },
  },
]);
