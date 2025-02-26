import Docker from "dockerode";

import process from "node:process";
import path from "node:path";
import { writeFile } from "node:fs/promises";

import loadNodeImage from "./load_node_image.js";
import { buildDockerfile } from "../src/buildDockerfile.js";

describe("buildDockerfile", () => {
  it(
    "should propagate failure",
    async () => {
      const dockerfilePath = path.join(process.env.TEST_TMPDIR!, "Dockerfile");

      await writeFile(
        dockerfilePath,
        `
      ARG BASE_IMAGE
      FROM \${BASE_IMAGE}
      RUN false`,
      );

      await expect(
        buildDockerfile(dockerfilePath, await loadNodeImage(), new Docker()),
      ).resolves.toEqual({
        ok: false,
        error: expect.stringMatching(
          /^Docker build failed:\n\n.*RUN false.*\n$/s,
        ),
      });
    },
    2 * 60 * 1000 /* 2mins: loading image can take time */,
  );
});
