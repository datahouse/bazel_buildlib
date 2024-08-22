import assert from "node:assert";

import type { ObjectExpression } from "estree";

import { ConfigPatcher } from "../src/ConfigPatcher.js";

import { addElement, addProperty, replaceExpr } from "../src/patches.js";

import { findPropertyValue } from "../src/astUtils.js";

const forceReplace = (obj: ObjectExpression, key: string, value: unknown) => {
  const node = findPropertyValue(obj, key);
  assert(node !== undefined);
  return replaceExpr(node, value);
};

describe("ConfigPatcher", () => {
  it("should replace a value", () => {
    const patcher = ConfigPatcher.create(`{a: 1, b: "f"}`);

    const patches = [forceReplace(patcher.root, "a", "bar")];

    expect(patcher.patch(patches)).toEqual(`{a: "bar", b: "f"}`);
  });

  it("should add multiple properties", () => {
    const patcher = ConfigPatcher.create(`{a: 1, b: "f"}`);

    const patches = [
      addProperty(patcher.root, "c", 1),
      addProperty(patcher.root, "d", "b"),
    ];

    expect(patcher.patch(patches)).toEqual(`{a: 1, b: "f","c": 1,\n"d": "b"}`);
  });

  it("should add array elements", () => {
    const patcher = ConfigPatcher.create(`{a: []}`);

    const node = findPropertyValue(patcher.root, "a");
    assert(node !== undefined && node.type === "ArrayExpression");

    const patches = [addElement(node, 1), addElement(node, "foo")];

    expect(patcher.patch(patches)).toEqual(`{a: [1,\n"foo"]}`);
  });

  it("should handle multiple splices", () => {
    const patcher = ConfigPatcher.create(`{a: 1, b: "f"}`);

    const patches = [
      forceReplace(patcher.root, "a", 2),
      forceReplace(patcher.root, "b", 3),
      addProperty(patcher.root, "c", 4),
    ];

    expect(patcher.patch(patches)).toEqual(`{a: 2, b: 3,"c": 4}`);
  });

  it("should respect trailing commas", () => {
    const patcher = ConfigPatcher.create(`{a: 1,}`);

    const patches = [addProperty(patcher.root, "b", 2)];

    expect(patcher.patch(patches)).toEqual(`{a: 1,"b": 2,}`);
  });

  it("should add to empty objects", () => {
    const patcher = ConfigPatcher.create(`{}`);

    const patches = [addProperty(patcher.root, "b", 2)];

    expect(patcher.patch(patches)).toEqual(`{"b": 2}`);
  });

  it(`should preserve comments`, () => {
    const patcher = ConfigPatcher.create(`{a: 1, /* yes */}`);

    const patches = [addProperty(patcher.root, "b", 2)];

    expect(patcher.patch(patches)).toEqual(`{a: 1, /* yes */"b": 2,}`);
  });
});
