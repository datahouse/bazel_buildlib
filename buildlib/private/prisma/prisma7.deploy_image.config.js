import { defineConfig, env } from "prisma/config";
export default defineConfig({
  // Deploy image has hardcoded env variable.
  datasource: { url: env("DATABASE_URL") },
});
