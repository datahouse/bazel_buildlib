import {
  GenericContainer,
  Wait,
  getContainerRuntimeClient,
} from "testcontainers";

import loadNodeTestImage from "./load_node_test_image.js";

test(
  "volumes",
  async () => {
    const image = await loadNodeTestImage();
    await using container = await new GenericContainer(image)
      .withWaitStrategy(Wait.forOneShotStartup())
      .start();

    // just running the container tests we can write to the volume.
    // the entrypoint would fail otherwise.

    // inspect the container
    const { dockerode } = (await getContainerRuntimeClient()).container;
    const inspect = await dockerode.getContainer(container.getId()).inspect();

    // check the volume is declared.
    expect(inspect.Config.Volumes).toEqual({ "/test_volume": {} });

    // Check we actually have a volume attached.
    // docker should attach volumes implicitly based on the volume instruction.
    expect(inspect.Mounts).toEqual([
      expect.objectContaining({
        Type: "volume",
        Driver: "local",
        Destination: "/test_volume",
      }),
    ]);
  },
  5 * 60 * 1000,
);
