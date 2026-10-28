import process from "node:process";
import { readFile } from "node:fs/promises";
import { join } from "node:path";

import Docker from "dockerode";

import { spawnInheritIO } from "../../js-lib/src/spawnInheritIO.js";

import {
  getComposeContainerAddress,
  type DcServiceReference,
} from "../../docker/compose/src/composeContainer.js";

import { getSchemaInfo } from "./schemaParsing.js";

interface Config {
  dbUrl: string;
  dbService: DcServiceReference;
  prismaExecDir?: string; // Prisma 5-6 only (when seed is set).
  prismaTool: string;
  schemaPath: string;
  prismaConfig?: string; // Prisma 7 or above.
  dbUrlEnv?: string; // Prisma 7 or above.
}

type ArgResult =
  { type: "args"; args: string[] } | { type: "err"; msg: string };

const getExtraArgs = (
  args: string[],
  schemaPath: string,
  prismaConfig: string | undefined,
): ArgResult => {
  if (prismaConfig != null) {
    return { type: "args", args: ["--config", prismaConfig] };
  }

  const emptyArgs: ArgResult = { type: "args", args: [] };
  const schemaArgs: ArgResult = {
    type: "args",
    args: ["--schema", schemaPath],
  };
  const skipGenerateArgs: ArgResult = {
    type: "args",
    args: ["--schema", schemaPath, "--skip-generate"],
  };

  const [cmd, subCmd] = args;

  switch (cmd) {
    case "version":
    case "-v":
      return emptyArgs;

    case "init":
      return {
        type: "err",
        msg: "Instead of using prisma init, set up the relevant prisma bazel rules.",
      };

    case "generate":
      return {
        type: "err",
        msg: "Instead of using prisma generate, use the prisma_generate bazel rule.",
      };

    case "introspect":
      return {
        type: "err",
        msg: "Instead of using prisma introspect, use db pull.",
      };

    case "validate":
      return {
        type: "err",
        msg: "The prisma_schema rule automatically validates the prisma schema.",
      };

    case "format":
      return schemaArgs;

    case "db":
      switch (subCmd) {
        case "pull":
          return schemaArgs;
        case "push":
          return skipGenerateArgs;
        case "seed":
          return emptyArgs;
        case "execute":
          return schemaArgs;
        default:
      }
      break;
    case "migrate":
      switch (subCmd) {
        case "dev":
          return skipGenerateArgs;
        case "reset":
          return skipGenerateArgs;
        case "deploy":
          return schemaArgs;
        case "resolve":
          return schemaArgs;
        case "status":
          return schemaArgs;
        case "diff":
          // Schema might be from or to target.
          // Let the user decide.
          return emptyArgs;
        default:
      }
      break;
    default:
  }

  const cmdStr = args.slice(0, 2).join(" ");

  return {
    type: "err",
    msg: `Unknown prisma command '${cmdStr}'\nPlease file a bug if you feel this is a mistake`,
  };
};

const loadDBAddr = async (dbService: DcServiceReference) => {
  const result = await getComposeContainerAddress(new Docker(), dbService);

  if (result.type === "err") {
    console.error(result.message);
    process.exit(1);
  }

  return result.address;
};

const getDbUrlEnv = async (schemaFullPath: string) => {
  const { dbUrlEnv } = getSchemaInfo(await readFile(schemaFullPath, "utf8"));

  if (dbUrlEnv == null)
    throw new Error(`No db url env found in ${schemaFullPath}.`);

  return dbUrlEnv;
};

const main = async () => {
  // Ignore first 2 args:
  // - The name of the node binary
  // - The path to the JS script.
  const [, , configPath, ...prismaArgs] = process.argv;

  const config = JSON.parse(await readFile(configPath, "utf8")) as Config;

  // Migrations get written relative to the schema.
  // So we must use the schema in the workspace to get the migrations into the source tree.
  const schemaFullPath = join(
    process.env.BUILD_WORKSPACE_DIRECTORY!,
    config.schemaPath,
  );

  const dbUrlEnv = config.dbUrlEnv ?? (await getDbUrlEnv(schemaFullPath));

  const dbUrl = new URL(config.dbUrl);
  dbUrl.host = await loadDBAddr(config.dbService);

  const extraArgsResult = getExtraArgs(
    prismaArgs,
    schemaFullPath,
    config.prismaConfig,
  );

  if (extraArgsResult.type === "err") {
    console.error(extraArgsResult.msg);
    process.exit(2);
  }

  const extraArgs = extraArgsResult.args;

  const env = {
    ...process.env,
    [dbUrlEnv]: dbUrl.href,
  };

  // Exec prisma in exec dir (for seed script package.json).
  const code = await spawnInheritIO(
    join(process.cwd(), config.prismaTool),
    [...prismaArgs, ...extraArgs],
    { cwd: config.prismaExecDir, env },
  );

  process.exit(code);
};

await main();
