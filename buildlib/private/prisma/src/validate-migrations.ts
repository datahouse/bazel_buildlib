import process from "node:process";
import { basename } from "node:path";
import { readFile } from "node:fs/promises";

import { inspect } from "node:util";

import { PostgreSqlContainer } from "@testcontainers/postgresql";

import {
  execFileWithCode,
  type ExecResult,
} from "../../js-lib/src/execFileWithCode.js";
import { loadImageDirToDocker } from "../../docker/src/loadImageToDocker.js";

// Strings / messages we match on.
const fakeMigrationName = "buildlib_migration_validation_fake_migration";
const failedToWriteMigration = "Failed to write the migration lock file";
const appliedMigrations = "The following migration(s) have been applied:";

interface Config {
  prismaCliPath: string;
  schemaPath: string;
  dbImageDir: string;
  dbUrlEnv: string;
  dbType: string;
}

const loadConfig = async (): Promise<Config> => {
  const fromEnv = (n: string) => {
    const v = process.env[n];
    if (!v) throw new Error(`${n} not set on env`);
    return v;
  };

  const fromEnvPath = (n: string) => readFile(fromEnv(n), "utf8");

  return {
    prismaCliPath: fromEnv("PRISMA_CLI_PATH"),
    schemaPath: fromEnv("PRISMA_SCHEMA_PATH"),
    dbImageDir: fromEnv("DB_IMAGE_DIR"),
    dbUrlEnv: await fromEnvPath("DB_URL_ENV"),
    dbType: await fromEnvPath("DB_TYPE"),
  };
};

const createDbContainer = (image: string, dbType: string) => {
  switch (dbType) {
    case "postgres":
      return new PostgreSqlContainer(image);
    default:
      throw new Error(
        `Database type ${dbType} not supported. Please file a buildlib issue if you need this DB type.`,
      );
  }
};

const runPrismaMigrateDev = async ({
  prismaCliPath,
  schemaPath,
  dbImageDir,
  dbUrlEnv,
  dbType,
}: Config) => {
  const image = await loadImageDirToDocker(dbImageDir);
  const container = await createDbContainer(image, dbType).start();

  try {
    const env = {
      ...process.env,
      [dbUrlEnv]: container.getConnectionUri(),
    };

    return await execFileWithCode(
      prismaCliPath,
      [
        "migrate",
        "dev",
        "--skip-generate",
        "--skip-seed",
        "--schema",
        schemaPath,
        // Pass a migration name. Otherwise prisma will try to read from stdin and hang.
        "--name",
        fakeMigrationName,
      ],
      { env },
    );
  } finally {
    await container.stop();
  }
};

const areMigrationsClean = (result: ExecResult) => {
  const { code, stdout, stderr } = result;

  if (code === 1 && stderr.includes(failedToWriteMigration)) {
    // Prisma dev attempted to create a migration.
    // Something is out of sync.
    return false;
  }

  if (stdout.includes(fakeMigrationName)) {
    // Migration was created.
    // Might happen with fully disabled sandboxing where prisma is actually
    // able to write the migration.
    return false;
  }

  if (code === 0 && stdout.includes(appliedMigrations)) {
    // Migrations are clean.
    return true;
  }

  throw new Error(
    `Unexpected prisma result:\n${inspect(result)}\n\nPlease report this if you think this is a buildlib bug.`,
  );
};

const main = async () => {
  const config = await loadConfig();

  const execResult = await runPrismaMigrateDev(config);

  const schemaName = basename(config.schemaPath);

  if (areMigrationsClean(execResult)) {
    console.log(`Prisma migrations are consistent with ${schemaName}.`);
  } else {
    console.error(
      `Prisma migrations are not consistent with ${schemaName}. Please run 'prisma migrate dev'.`,
    );
    process.exit(1);
  }
};

await main();
