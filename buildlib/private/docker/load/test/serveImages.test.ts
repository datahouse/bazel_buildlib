import { env } from "node:process";

import Docker from "dockerode";

import { OCIImage } from "../../lib/src/OCIImage.js";
import { serveImages, serveImagesWithPort } from "../src/serveImages.js";

describe("serveImages", () => {
  it(
    "serves images that can be loaded by docker",
    async () => {
      const docker = new Docker();

      const repoName = "fake-repo";

      // imageDir contains a single-image OCI layout
      const imageDir = env.NODE_IMAGE_FOR_SERVE_IMAGES_TEST!;
      const {
        manifestDescriptor: { digest },
      } = await OCIImage.load(imageDir);

      await using registry = await serveImages(new Map([[repoName, imageDir]]));

      const stream = await docker.pull(
        `${registry.address}/${repoName}@${digest}`,
      );

      const result = new Promise((resolve, reject) => {
        docker.modem.followProgress(stream, (err, res) =>
          err ? reject(err) : resolve(res),
        );
      });

      await expect(result).resolves.not.toThrow();
    },
    60 * 1000 /* 1min */,
  );

  it("detects a port in use", async () => {
    const noImages = new Map<string, string>();

    await using registry0 = await serveImages(noImages);

    // Try and run a registry on the same port.
    await using registry1 = await serveImagesWithPort(noImages, registry0.port);

    expect(registry1).toBeUndefined();
  });
});
