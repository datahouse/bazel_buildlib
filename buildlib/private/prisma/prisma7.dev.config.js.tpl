import { join, dirname } from "node:path";

import { defineConfig, env } from "prisma/config";

const schema = join(env("BUILD_WORKSPACE_DIRECTORY"), {{SCHEMA_PATH}});

export default defineConfig({
  schema,
  migrations: {
    path: join(dirname(schema), "migrations"),
    seed: {{SEED_SCRIPT}},
  },
  datasource: { url: env({{DB_URL_ENV}}) },
});
