import { GenericContainer, Network, Wait } from "testcontainers";
import { PostgreSqlContainer } from "@testcontainers/postgresql";

import loadPostgresImage from "./load_postgres_image.js";
import loadNodeImage from "./load_node_image.js";

test(
  "connect from container",
  async () => {
    const [psqlImage, nodeImage] = await Promise.all([
      loadPostgresImage(),
      loadNodeImage(),
    ]);

    await using network = await new Network().start();
    await using psqlContainer = await new PostgreSqlContainer(psqlImage)
      .withNetwork(network)
      .start();

    const dbUrl = new URL(psqlContainer.getConnectionUri());
    dbUrl.hostname = psqlContainer.getHostname();
    dbUrl.port = "5432";

    const containerPromise = new GenericContainer(nodeImage)
      .withEnvironment({ DATABASE_URL: dbUrl.toString() })
      .withNetwork(network)
      .withWaitStrategy(Wait.forOneShotStartup())
      .start();

    await expect(containerPromise).resolves.not.toThrow();
  },
  60 * 1000,
);
