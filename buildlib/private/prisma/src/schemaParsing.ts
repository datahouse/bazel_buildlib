import { lang, query } from "@renovatebot/good-enough-parser";

// At the time of writing, good-enough-parser had minimal documentation; the codebase itself was the reference.
const prismaSchemaLang = lang.createLang({
  lexer: {
    joinLines: null,
    comments: [
      { type: "line-comment", startsWith: "//" },
      { type: "line-comment", startsWith: "///" },
      { type: "multiline-comment", startsWith: "/*", endsWith: "*/" },
    ],
    symbols: /[_a-zA-Z][_a-zA-Z0-9]*/,
    operators: ["="],
    numbers: /[0-9]+/,
    brackets: [
      { startsWith: "{", endsWith: "}" },
      { startsWith: "[", endsWith: "]" },
      { startsWith: "(", endsWith: ")" },
    ],
    strings: [{ startsWith: '"', escapeChar: "\\" }],
  },
  parser: {
    useIndentBlocks: false,
  },
});

export interface SchemaInfo {
  provider?: string;
  dbUrlEnv?: string;
}

export const getSchemaInfo = (schema: string): SchemaInfo => {
  const providerQ = query
    .sym<SchemaInfo>("provider")
    .op("=")
    .str((ctx, token) => ({ ...ctx, provider: token.value }));

  const dbUrlEnvQ = query
    .sym<SchemaInfo>("url")
    .op("=")
    .sym("env")
    .tree({
      maxDepth: 1,
      startsWith: "(",
      endsWith: ")",
      search: query.str<SchemaInfo>((ctx, token) => ({
        ...ctx,
        dbUrlEnv: token.value,
      })),
    });

  const q = query
    .sym<SchemaInfo>("datasource")
    .sym() // datasource name, irrelevant
    .tree({
      maxDepth: 1,
      startsWith: "{",
      endsWith: "}",
      search: query.alt(providerQ, dbUrlEnvQ),
    });

  const emptyResult: SchemaInfo = {};

  return prismaSchemaLang.query(schema, q, emptyResult) ?? emptyResult;
};
