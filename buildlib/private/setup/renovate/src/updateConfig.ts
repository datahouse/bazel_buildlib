import type { Node, ObjectExpression } from "estree";

import { ConfigPatcher } from "./ConfigPatcher.js";
import { findPropertyValue, isLiteralValue } from "./astUtils.js";
import { Patch, addElement, addProperty, replaceExpr } from "./patches.js";

export interface Values {
  pnpmVersion: string;
  latestNodeVersion: string;
}

const forceLiteralValue = (node: Node, value: unknown): Patch[] =>
  isLiteralValue(node, value) ? [] : [replaceExpr(node, value)];

const patchPnpmVersion = (
  constraints: ObjectExpression,
  { pnpmVersion }: Values,
): Patch[] => {
  const pnpm = findPropertyValue(constraints, "pnpm");

  if (!pnpm) return [addProperty(constraints, "pnpm", pnpmVersion)];

  return forceLiteralValue(pnpm, pnpmVersion);
};

const patchConstraints = (
  config: ObjectExpression,
  values: Values,
): Patch[] => {
  const { pnpmVersion } = values;

  const minConfig = { pnpm: pnpmVersion };

  const constraints = findPropertyValue(config, "constraints");
  if (!constraints) return [addProperty(config, "constraints", minConfig)];

  if (constraints.type !== "ObjectExpression")
    return [replaceExpr(constraints, minConfig)];

  return patchPnpmVersion(constraints, values);
};

const getAllowedNodeVersionsFromPackageRule = (
  elem: Node | null,
): Node | undefined => {
  if (elem === null || elem.type !== "ObjectExpression") return undefined;

  if (elem.properties.length !== 2) return undefined;

  const match = findPropertyValue(elem, "matchPackageNames");
  if (!match || match.type !== "ArrayExpression") return undefined;

  if (!match.elements.find((n) => n !== null && isLiteralValue(n, "node")))
    return undefined;

  return findPropertyValue(elem, "allowedVersions");
};

const patchPackageRules = (
  config: ObjectExpression,
  values: Values,
): Patch[] => {
  const allowedVersions = `<= ${values.latestNodeVersion}`;

  const minConfig = {
    matchPackageNames: ["node"],
    allowedVersions,
  };

  const packageRules = findPropertyValue(config, "packageRules");
  if (!packageRules) return [addProperty(config, "packageRules", [minConfig])];

  if (packageRules.type !== "ArrayExpression")
    return [replaceExpr(packageRules, [minConfig])];

  for (const elem of packageRules.elements) {
    const node = getAllowedNodeVersionsFromPackageRule(elem);

    if (node) return forceLiteralValue(node, allowedVersions);
  }

  return [addElement(packageRules, minConfig)];
};

export const updateConfig = (config: string, values: Values): string => {
  const patcher = ConfigPatcher.create(config);

  const patches = [
    ...patchConstraints(patcher.root, values),
    ...patchPackageRules(patcher.root, values),
  ];

  return patcher.patch(patches);
};
