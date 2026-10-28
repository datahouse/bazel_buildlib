import { GenericContainer } from "testcontainers";

import loadHotBaseTestImage from "./load_hot_base_test_image.js";
import loadHotBaseTestImageTailwind from "./load_hot_base_test_image_tailwind.js";

describe.each([
  ["plain", loadHotBaseTestImage, "0"],
  ["with tailwind", loadHotBaseTestImageTailwind, "1"],
])("hot reload base (%s)", (_variant, loadImage, expectedTailwindEnv) => {
  it(
    "starts and sets DH_BUILDLIB_REACT_APP_TAILWIND",
    async () => {
      const hotBaseTestImage = await loadImage();

      await using container = await new GenericContainer(hotBaseTestImage)
        .withExposedPorts(80) // expose the port so testcontainers waits for it to be bound.
        .start();

      // Container started \o/

      // A somewhat unnecessary expect to make the linter happy.
      expect(container.getMappedPort(80)).not.toEqual(0);

      const { exitCode, stdout } = await container.exec([
        "printenv",
        "DH_BUILDLIB_REACT_APP_TAILWIND",
      ]);

      expect([exitCode, stdout.trim()]).toEqual([0, expectedTailwindEnv]);
    },
    5 * 60 * 1000,
  );
});
