import { readFile, writeFile } from "node:fs/promises";

import argparse from "argparse";

import { execFileWithCode } from "../../js-lib/src/execFileWithCode.js";

import { getSchemaInfo } from "./schemaParsing.js";

const parseArgs = () => {
  const parser = new argparse.ArgumentParser({
    description: "Prisma schema validator",
  });

  parser.add_argument("--prismaCli", {
    help: "Prisma CLI tool",
    required: true,
  });
  parser.add_argument("--schemaPath", {
    help: "Schema to validate",
    required: true,
  });
  parser.add_argument("--validationMarker", {
    help: "Bazel validation marker (written if validation OK).",
    required: true,
  });
  return parser.parse_args<{
    prismaCli: string;
    schemaPath: string;
    validationMarker: string;
  }>();
};

// Mapping from provider -> fake URL for running validation.
//
// Prisma requires DB urls be set even during validation; the URLs only need to
// be structurally valid (no DB needs to run there).
//
// Provider list:
// https://www.prisma.io/docs/orm/reference/prisma-schema-reference#fields
const fakeDBUrls = new Map([
  ["sqlite", "file:./fake.db"],
  ["postgresql", "postgres://fake.localhost/"],
  ["mysql", "mysql://fake.localhost/fakeDB"],
  ["sqlserver", "sqlserver://fake.localhost;database=fakeDB"],
  ["mongodb", "mongodb://fake.localhost/"],
  ["cockroachdb", "postgres://fake.localhost/"],
]);

const getValidationEnv = async (schemaPath: string) => {
  const { provider, dbUrlEnv } = getSchemaInfo(
    await readFile(schemaPath, "utf8"),
  );

  if (!dbUrlEnv) {
    // no env variable for DB needed.
    return {};
  }

  if (!provider) {
    console.error(`No provider found in ${schemaPath}`);
    process.exit(1);
  }

  const fakeDBUrl = fakeDBUrls.get(provider);

  if (!fakeDBUrl) {
    console.error(`Unknown provider ${provider}`);
    process.exit(1);
  }

  return { [dbUrlEnv]: fakeDBUrl };
};

const main = async () => {
  const { prismaCli, schemaPath, validationMarker } = parseArgs();

  const env = await getValidationEnv(schemaPath);

  const { code, stderr } = await execFileWithCode(
    prismaCli,
    ["validate", "--schema", schemaPath],
    { env: { ...env, BAZEL_BINDIR: "." } },
  );

  if (code !== 0) {
    process.stderr.write(stderr);
    process.exit(code);
  }

  await writeFile(validationMarker, "");
};

await main();
