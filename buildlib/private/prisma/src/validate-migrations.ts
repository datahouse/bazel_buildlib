import process from "node:process";
import { dirname, basename, join } from "node:path";
import { readFile, mkdtemp, rm, cp, writeFile } from "node:fs/promises";

import { inspect } from "node:util";

import { PostgreSqlContainer } from "@testcontainers/postgresql";

import {
  execFileWithCode,
  type ExecResult,
} from "../../js-lib/src/execFileWithCode.js";
import { serveImage } from "../../docker/load/src/serveImages.js";
import { getSchemaInfo } from "./schemaParsing.js";

// Strings / messages we match on.
const fakeMigrationName = "buildlib_migration_validation_fake_migration";
const failedToWriteMigration = "Failed to write the migration lock file";
const appliedMigrations = "The following migration(s) have been applied:";

interface Config {
  prismaCliPath: string;
  schemaPath: string;
  dbImageDir: string;
  prisma7OrAbove: boolean;
}

const loadConfig = (): Config => {
  const fromEnv = (n: string) => {
    const v = process.env[n];
    if (!v) throw new Error(`${n} not set on env`);
    return v;
  };

  return {
    prismaCliPath: fromEnv("PRISMA_CLI_PATH"),
    schemaPath: fromEnv("PRISMA_SCHEMA_PATH"),
    dbImageDir: fromEnv("DB_IMAGE_DIR"),
    prisma7OrAbove: !!parseInt(fromEnv("PRISMA7_OR_ABOVE"), 10),
  };
};

const createDbContainer = (image: string, provider: string) => {
  switch (provider) {
    case "postgresql":
      return new PostgreSqlContainer(image);
    default:
      throw new Error(
        `Database provider ${provider} not supported. Please file a buildlib issue if you need this provider type.`,
      );
  }
};

// polyfill for fsPromises.mkdtempDisposable
// TODO: Replace with upstream, once we have Node.js 24.4.0 everywhere.
const mkdtempDisposable = async (prefix: string) => {
  const path = await mkdtemp(prefix);
  const remove = () => rm(path, { recursive: true });
  return {
    path,
    remove,
    [Symbol.asyncDispose]: remove,
  };
};

const preparePrisma56 = async (
  tmpDirPath: string,
  schemaPath: string,
  dbUrl: string,
  dbUrlEnv?: string,
) => {
  // Pass the DB URL via env var and use --schema flag.
  // The migrations folder is identified relative to the schema.
  // Therefore, we need to copy the schema to the temp directory as well.

  const tmpSchemaPath = join(tmpDirPath, basename(schemaPath));
  await cp(schemaPath, tmpSchemaPath);

  if (dbUrlEnv == null)
    throw new Error(`No db url env found in ${schemaPath}.`);

  return {
    env: {
      ...process.env,
      [dbUrlEnv]: dbUrl,
    },
    cfgArgs: ["--skip-generate", "--skip-seed", "--schema", tmpSchemaPath],
  };
};

const preparePrisma7OrAbove = async (
  tmpDirPath: string,
  schemaPath: string,
  dbUrl: string,
) => {
  // Pass DB URL via config file and use --config flag.
  const tmpConfigPath = join(tmpDirPath, "config.js");

  const prismaConfig = {
    schema: join(process.cwd(), schemaPath),
    migrations: { path: "migrations" },
    datasource: { url: dbUrl },
  };

  await writeFile(
    tmpConfigPath,
    `export default ${JSON.stringify(prismaConfig)}`,
  );

  return {
    env: process.env,
    cfgArgs: ["--config", tmpConfigPath],
  };
};

const runPrismaMigrateDev = async ({
  prismaCliPath,
  schemaPath,
  dbImageDir,
  prisma7OrAbove,
}: Config) => {
  const { provider, dbUrlEnv } = getSchemaInfo(
    await readFile(schemaPath, "utf8"),
  );

  if (provider == null)
    throw new Error(`No database provider found in ${schemaPath}.`);

  await using image = await serveImage(dbImageDir);
  await using container = await createDbContainer(image.ref, provider).start();

  const dbUrl = container.getConnectionUri();

  // Create a temporary directory to copy migrations to:
  //
  // The migration consistency test relies on attempting to create a migration
  // to detect drift. If there is drift, an actual migration is created.
  //
  // Under very aggressive bazel sandbox settings, this will fail, because prisma
  // will attempt to modify input files (e.g. migration_lock.toml), which is not allowed.
  //
  // As a result, the user will be presented with a rather cryptic error
  // (something like "I/O error, migration_lock.toml modified") as opposed to a
  // message explaining that the migrations are not consistent with the schema.
  //
  // To mitigate this, we copy relevant files to a temporary directory, where it
  // is OK if they are modified.
  await using tmpDir = await mkdtempDisposable(
    join(process.env.TEST_TMPDIR!, "migrate-test-tmp-"),
  );

  const migrationsDirname = "migrations";
  const tmpMigrationsPath = join(tmpDir.path, migrationsDirname);

  await cp(join(dirname(schemaPath), migrationsDirname), tmpMigrationsPath, {
    recursive: true,
  });

  const { env, cfgArgs } = prisma7OrAbove
    ? await preparePrisma7OrAbove(tmpDir.path, schemaPath, dbUrl)
    : await preparePrisma56(tmpDir.path, schemaPath, dbUrl, dbUrlEnv);

  return await execFileWithCode(
    prismaCliPath,
    [
      "migrate",
      "dev",
      ...cfgArgs,
      // Pass a migration name so we can easily recognize it was created from the output.
      //
      // This also prevents prisma from trying to read stdin and hang.
      // (an alternative would be to set "CI" in the env but that would create a
      // migration with an empty name)
      "--name",
      fakeMigrationName,
    ],
    { env },
  );
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
  const config = loadConfig();

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
