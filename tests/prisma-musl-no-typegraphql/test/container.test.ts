import { GenericContainer, Network, Wait } from "testcontainers";
import { PostgreSqlContainer } from "@testcontainers/postgresql";

import loadPostgresImage from "./load_postgres_image.js";
import loadMuslImage from "./load_musl_image.js";

test(
  "container startup",
  async () => {
    const [psqlImage, muslImage] = await Promise.all([
      loadPostgresImage(),
      loadMuslImage(),
    ]);

    await using network = await new Network().start();
    await using psqlContainer = await new PostgreSqlContainer(psqlImage)
      .withNetwork(network)
      .start();

    const dbUrl = new URL(psqlContainer.getConnectionUri());
    dbUrl.hostname = psqlContainer.getHostname();
    dbUrl.port = "5432";

    const containerPromise = new GenericContainer(muslImage)
      .withEnvironment({ DATABASE_URL: dbUrl.toString() })
      .withNetwork(network)
      .withWaitStrategy(Wait.forOneShotStartup())
      .start();

    await expect(containerPromise).resolves.not.toThrow();
  },
  60 * 1000,
);
