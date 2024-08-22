import assert from "node:assert";
import { inspect } from "node:util";

import { parseModule, Token as EsprimaToken } from "esprima";

import type { Node, ObjectExpression, ArrayExpression } from "estree";

import type { Patch } from "./patches.js";

// Esprima's typing does not have the `range` field, even though it is present if
// we pass { range: true, token: true } to esprima.
interface Token extends EsprimaToken {
  range: [number, number];
}

type Comma = "trailing" | "none" | "leading";

const unreachable = (x: never): never => {
  throw new Error(`unreachable ${inspect(x)}`);
};

const applyComma = (content: string, comma: Comma): string => {
  switch (comma) {
    case "trailing":
      return `${content},`;
    case "none":
      return content;
    case "leading":
      return `,${content}`;
    default:
      return unreachable(comma);
  }
};

interface Splice {
  range: [number, number];
  content: string;
}

const groupByTarget = (patches: Patch[]): Map<Node, Patch[]> => {
  const byTarget = new Map<Node, Patch[]>();

  patches.forEach((p) => {
    const arr = byTarget.get(p.target);
    if (arr) arr.push(p);
    else byTarget.set(p.target, [p]);
  });

  return byTarget;
};

const exportPrefix = "export default ";

export class ConfigPatcher {
  private constructor(
    private config: string,
    readonly root: ObjectExpression,
    private tokens: Token[],
  ) {}

  static create(config: string): ConfigPatcher {
    // Create a synthetic default export to parse as module.
    const { tokens, body } = parseModule(exportPrefix + config, {
      range: true,
      tokens: true,
    });

    const decl = body[0];

    assert(
      decl.type === "ExportDefaultDeclaration",
      `unexpected body type: ${decl.type}`,
    );
    assert(
      decl.declaration.type === "ObjectExpression",
      `unexpected declaration type: ${decl.declaration.type}`,
    );

    return new ConfigPatcher(
      config,
      decl.declaration,
      tokens as Token[], // cast to tokens that also have a range param.
    );
  }

  patch(patches: Patch[]): string {
    const byTarget = groupByTarget(patches);

    const splices = Array.from(byTarget, ([t, ps]) =>
      this.spliceForPatches(t, ps),
    );

    return this.applySplices(splices);
  }

  private spliceForPatches(target: Node, patches: Patch[]): Splice {
    assert(patches.length >= 1);

    const tpe = patches[0].type;

    switch (tpe) {
      case "ReplaceExpr":
        return this.spliceForReplaceExpr(target, patches);
      case "AddProperty":
        return this.spliceForAddProperty(target, patches);
      case "AddElement":
        return this.spliceForAddElement(target, patches);
      default:
        return unreachable(tpe);
    }
  }

  private applySplices(splices: Splice[]): string {
    const rangeOffset = exportPrefix.length;

    let { config } = this;

    // Sort in descending order so patches we apply first do not mess up ranges.
    // Assume patches do not intersect.
    splices.sort((x, y) => y.range[0] - x.range[0]);

    for (const patch of splices) {
      config =
        config.slice(0, patch.range[0] - rangeOffset) +
        patch.content +
        config.slice(patch.range[1] - rangeOffset);
    }

    return config;
  }

  private spliceForReplaceExpr(target: Node, patches: Patch[]): Splice {
    assert(
      patches.length === 1,
      `got multiple replacements: ${inspect(patches)}`,
    );
    return { range: target.range!, content: JSON.stringify(patches[0].value) };
  }

  private spliceForAddProperty(target: Node, patches: Patch[]): Splice {
    assert(
      target.type === "ObjectExpression",
      `bad target for AddProperty patch: ${inspect(target)}`,
    );

    const propsStr = patches
      .map((p) => {
        assert(
          p.type === "AddProperty",
          `non-AddProperty patch for ${inspect(target)}, got: ${inspect(p)}`,
        );
        const keyStr = JSON.stringify(p.key);
        const valueStr = JSON.stringify(p.value);
        return `${keyStr}: ${valueStr}`;
      })
      .join(",\n");

    const content = applyComma(propsStr, this.commaForPatch(target));
    const splicePoint = target.range![1] - 1;

    return {
      range: [splicePoint, splicePoint],
      content,
    };
  }

  private spliceForAddElement(target: Node, patches: Patch[]): Splice {
    assert(
      target.type === "ArrayExpression",
      `bad target for AddElement patch: ${inspect(target)}`,
    );

    const propsStr = patches
      .map((p) => {
        assert(
          p.type === "AddElement",
          `non-AddElement patch for ${inspect(target)}, got: ${inspect(p)}`,
        );
        return JSON.stringify(p.value);
      })
      .join(",\n");

    const content = applyComma(propsStr, this.commaForPatch(target));
    const splicePoint = target.range![1] - 1;

    return {
      range: [splicePoint, splicePoint],
      content,
    };
  }

  private commaForPatch(target: ObjectExpression | ArrayExpression): Comma {
    const [start, end] = target.range!;

    const endTokenIdx = this.tokens.findIndex((t) => t.range[1] === end);
    assert(
      this.tokens[endTokenIdx].value === "}" ||
        this.tokens[endTokenIdx].value === "]",
    );

    const prevTok = this.tokens[endTokenIdx - 1];

    if (prevTok.type === "Punctuator") {
      if (prevTok.value === "{" || prevTok.value === "[") {
        assert(prevTok.range[0] === start);
        return "none"; // object/array was empty
      }

      if (prevTok.value === ",") {
        return "trailing"; // keep the trailing comma
      }
    }

    // there was a property/element
    return "leading";
  }
}
