import { text } from "node:stream/consumers";
import { GenericContainer, Network, Wait } from "testcontainers";
import { PostgreSqlContainer } from "@testcontainers/postgresql";

import loadPrismaDeployDefaultImage from "./load_deploy_image_default.js";
import loadPrismaDeployAlpineImage from "./load_deploy_image_alpine.js";
import loadPostgresImage from "./load_postgres_image.js";

const runContainerOneShot = async (
  container: GenericContainer,
): Promise<string> => {
  await using startedContainer = await container
    .withWaitStrategy(Wait.forOneShotStartup())
    .start();

  return text(await startedContainer.logs());
};

describe("prisma deploy image", () => {
  // this runs prisma version; it ensures that arguments are being passed to
  // the prisma cli and the resulting output is a json object which contains a
  // prisma field which matches a version regex
  it(
    "can run prisma cli with version passed as argument",
    async () => {
      const container = new GenericContainer(
        await loadPrismaDeployDefaultImage(),
      ).withCommand(["prisma", "version", "--json"]);

      const output = await runContainerOneShot(container);
      const parsedOutput = JSON.parse(output);
      expect(parsedOutput).toHaveProperty(
        "prisma",
        expect.stringMatching(/[0-9]+\.[0-9]+\.[0-9]+/i),
      );
    },
    5 * 60 * 1000,
  );

  // this spins up a new network and postgres container dedicated for this
  // test; it performs a migration based on the content which is add to the test
  // deploy image.
  it.each<[string, () => Promise<string>]>([
    ["default image", loadPrismaDeployDefaultImage],
    ["alpine image", loadPrismaDeployAlpineImage],
  ])(
    "can run the default container behaviour performing prisma migrate deploy",
    async (_, loadImageFunction) => {
      await using network = await new Network().start();
      const postgresImage = await loadPostgresImage();
      await using psqlContainer = await new PostgreSqlContainer(postgresImage)
        .withNetwork(network)
        .start();
      const databaseUrl = new URL(psqlContainer.getConnectionUri());
      databaseUrl.hostname = psqlContainer.getHostname(); // docker container hostname
      databaseUrl.port = "5432";

      const container = new GenericContainer(await loadImageFunction())
        .withEnvironment({ DATABASE_URL: databaseUrl.toString() })
        .withNetwork(network);

      const output = await runContainerOneShot(container);
      expect(output).toMatch(/1 migration found in prisma\/migrations/);
      expect(output).toMatch(
        /Applying migration `20250404145926_database_initialization/,
      );
      expect(output).toMatch(/All migrations have been successfully applied./);
    },
    5 * 60 * 1000,
  );
});
