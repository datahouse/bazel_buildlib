import { PostgreSqlContainer } from "@testcontainers/postgresql";

import loadPostgresImage from "./load_postgres_image.js";

import { PrismaClient } from "../prisma/client/client.js";

test(
  "connect from jest test",
  async () => {
    const psqlImage = await loadPostgresImage();
    await using psqlContainer = await new PostgreSqlContainer(
      psqlImage,
    ).start();

    const url = psqlContainer.getConnectionUri();

    const prisma = new PrismaClient({ datasources: { db: { url } } });

    await expect(prisma.$connect()).resolves.not.toThrow();
  },
  60 * 1000,
);
