import { GenericContainer } from "testcontainers";

import loadHotBaseTestImage from "./load_hot_base_test_image.js";

describe("hot reload base", () => {
  it(
    "starts",
    async () => {
      const hotBaseTestImage = await loadHotBaseTestImage();

      await using container = await new GenericContainer(hotBaseTestImage)
        .withExposedPorts(80) // expose the port so testcontainers waits for it to be bound.
        .start();

      // Container started \o/

      // A somewhat unnecessary expect to make the linter happy.
      expect(container.getMappedPort(80)).not.toEqual(0);
    },
    5 * 60 * 1000,
  );
});
