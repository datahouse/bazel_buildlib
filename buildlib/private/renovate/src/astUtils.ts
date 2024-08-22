import type { Node, ObjectExpression, Property } from "estree";

const checkPropertyKey = (node: Property, key: string): boolean => {
  switch (node.key.type) {
    case "Identifier":
      return node.key.name === key;

    case "Literal":
      return node.key.value === key;

    default:
      return false;
  }
};

export const findPropertyValue = (
  { properties }: ObjectExpression,
  key: string,
): Node | undefined => {
  for (const prop of properties) {
    if (prop.type !== "SpreadElement" && checkPropertyKey(prop, key))
      return prop.value;
  }

  return undefined;
};

export const isLiteralValue = (node: Node, value: unknown): boolean =>
  node.type === "Literal" && node.value === value;
