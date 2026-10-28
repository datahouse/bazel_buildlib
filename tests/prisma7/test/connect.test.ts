import { PostgreSqlContainer } from "@testcontainers/postgresql";

import { PrismaPg } from "@prisma/adapter-pg";

import loadPostgresImage from "./load_postgres_image.js";

import { PrismaClient } from "../prisma/client/client.js";

test(
  "connect from jest test",
  async () => {
    const psqlImage = await loadPostgresImage();
    await using psqlContainer = await new PostgreSqlContainer(
      psqlImage,
    ).start();

    const adapter = new PrismaPg({
      connectionString: psqlContainer.getConnectionUri(),
    });

    const prisma = new PrismaClient({ adapter });

    await expect(prisma.$connect()).resolves.not.toThrow();
  },
  60 * 1000,
);
