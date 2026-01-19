import * as esprima from "esprima";
import type { Program, Node } from "estree";

const baseConfigPath = "./bazel-bin/dhDefaults.eslint.config.js";

const isIdent = (node: Node, name: string): boolean =>
  node.type === "Identifier" && node.name === name;

const isDhDefaultsReExport = (node: Node): boolean => {
  // export { default } from "./bazel-bin/dhDefaults.eslint.config.js";
  if (node.type !== "ExportNamedDeclaration") return false;
  if (node.source?.value !== baseConfigPath) return false;

  return node.specifiers.some(
    ({ local, exported }) =>
      isIdent(local, "default") && isIdent(exported, "default"),
  );
};

const isNamedDefineConfigImport = (node: Node): boolean => {
  // import { defineConfig } from "eslint/config"
  if (node.type !== "ImportDeclaration") return false;
  if (node.source.value !== "eslint/config") return false;

  return node.specifiers.some(
    (spec) =>
      spec.type === "ImportSpecifier" &&
      isIdent(spec.imported, "defineConfig") &&
      isIdent(spec.local, "defineConfig"),
  );
};

const isDefaultDhDefaultsImport = (node: Node): boolean => {
  // import dhDefaults from "<baseConfigPath>"
  if (node.type !== "ImportDeclaration") return false;
  if (node.source.value !== baseConfigPath) return false;

  return node.specifiers.some(
    (spec) =>
      spec.type === "ImportDefaultSpecifier" &&
      isIdent(spec.local, "dhDefaults"),
  );
};

/**
 * Checks whether a program contains:
 *   export default defineConfig([dhDefaults, ...]);
 */
const hasDefineConfigDhDefaultsExport = (program: Program): boolean => {
  const exportDefault = program.body.find(
    (node) => node.type === "ExportDefaultDeclaration",
  );

  const call = exportDefault?.declaration;
  if (call?.type !== "CallExpression") return false;

  if (!isIdent(call.callee, "defineConfig")) {
    return false;
  }

  const [flatConfigArray] = call.arguments;
  if (flatConfigArray?.type !== "ArrayExpression") return false;

  const [dhDefaultsConfig] = flatConfigArray.elements;
  return !!dhDefaultsConfig && isIdent(dhDefaultsConfig, "dhDefaults");
};

const hasRequiredConfigStructure = (program: Program): boolean =>
  program.body.some(isNamedDefineConfigImport) &&
  program.body.some(isDefaultDhDefaultsImport) &&
  hasDefineConfigDhDefaultsExport(program);

export const checkEslintConfig = (source: string): string | null => {
  const program = esprima.parseModule(source);

  if (
    program.body.some(isDhDefaultsReExport) ||
    hasRequiredConfigStructure(program)
  ) {
    return null;
  }

  return `
eslint.config.js does not follow the required structure:

import { defineConfig } from "eslint/config";
import dhDefaults from "./bazel-bin/eslintrc.dh-defaults.js";

// your imports / variables

export default defineConfig([
  dhDefaults,
  /*your additional config*/
]);
  `;
};
