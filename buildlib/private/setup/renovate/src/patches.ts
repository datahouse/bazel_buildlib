import type { ArrayExpression, Node, ObjectExpression } from "estree";

export type Patch = ReplaceExpr | AddProperty | AddElement;

interface ReplaceExpr {
  type: "ReplaceExpr";
  target: Node;
  value: unknown;
}

interface AddProperty {
  type: "AddProperty";
  target: ObjectExpression;
  key: string;
  value: unknown;
}

interface AddElement {
  type: "AddElement";
  target: ArrayExpression;
  value: unknown;
}

export const replaceExpr = (target: Node, value: unknown): Patch => ({
  type: "ReplaceExpr",
  target,
  value,
});

export const addProperty = (
  target: ObjectExpression,
  key: string,
  value: unknown,
): Patch => ({ type: "AddProperty", target, key, value });

export const addElement = (target: ArrayExpression, value: unknown): Patch => ({
  type: "AddElement",
  target,
  value,
});
