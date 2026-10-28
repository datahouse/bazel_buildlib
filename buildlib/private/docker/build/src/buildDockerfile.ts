import { dirname, basename } from "node:path";
import { realpath } from "node:fs/promises";
import streamConsumers from "node:stream/consumers";

import type Docker from "dockerode";

import { z } from "zod";

import { serveImage } from "../../load/src/serveImages.js";

// See
// https://github.com/moby/moby/blob/796da163f92ad486a4f0118b4008d9bd17b27c2e/pkg/jsonmessage/jsonmessage.go#L145-L158
const dockerMsgSchema = z.union([
  z.object({ stream: z.string() }),
  z.object({ error: z.string() }),
  z.object({ status: z.string() }),
  z.object({
    aux: z.object({
      ID: z.string().startsWith("sha256:"),
    }),
  }),
]);

export type BuildResult =
  { ok: true; id: string } | { ok: false; error: string };

export const buildDockerfile = async (
  dockerfileSymPath: string,
  baseImageDir: string,
  docker: Docker,
): Promise<BuildResult> => {
  // resolve symlinks, dockerode does not follow them.
  const dockerfilePath = await realpath(dockerfileSymPath);
  const dockerfileName = basename(dockerfilePath);

  await using baseImage = await serveImage(baseImageDir);

  const response = await streamConsumers.text(
    await docker.buildImage(
      { context: dirname(dockerfilePath), src: [dockerfileName] },
      {
        dockerfile: dockerfileName,
        buildargs: {
          BASE_IMAGE: baseImage.ref,
        },
        networkmode: "none", // no internet access!
        nocache: true, // leave caching to bazel
        forcerm: true, // leave less garbage in case of failure.
      },
    ),
  );

  let buildOut = "";
  let lastID: undefined | string;

  for (const line of response.trim().split("\n")) {
    const obj = dockerMsgSchema.parse(JSON.parse(line));

    if ("stream" in obj) {
      buildOut += obj.stream;
    } else if ("error" in obj) {
      const error = `Docker build failed:\n\n${buildOut}\n${obj.error}\n`;
      return { ok: false, error };
    } else if ("status" in obj) {
      // pull status, ignore
    } else {
      lastID = obj.aux.ID;
    }
  }

  if (lastID === undefined)
    throw new Error(`No aux object in response:${response}`);

  return { ok: true, id: lastID };
};
