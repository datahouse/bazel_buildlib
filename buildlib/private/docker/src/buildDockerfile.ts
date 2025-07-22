import tar from "tar-stream";
import type Docker from "dockerode";

import { createReadStream } from "node:fs";
import { stat } from "node:fs/promises";
import { pipeline } from "node:stream/promises";
import streamConsumers from "node:stream/consumers";

import { z } from "zod";

// See
// https://github.com/moby/moby/blob/796da163f92ad486a4f0118b4008d9bd17b27c2e/pkg/jsonmessage/jsonmessage.go#L145-L158
const dockerMsgSchema = z.union([
  z.object({ stream: z.string() }),
  z.object({ error: z.string() }),
  z.object({
    aux: z.object({
      ID: z.string().startsWith("sha256:"),
    }),
  }),
]);

const streamDockerfile = async (dockerfile: string, pack: tar.Pack) => {
  const { size } = await stat(dockerfile);
  const entry = pack.entry({ name: "Dockerfile", size });
  await pipeline(createReadStream(dockerfile), entry);
  pack.finalize();
};

export type BuildResult =
  | { ok: true; id: string }
  | { ok: false; error: string };

const build = async (
  baseImageID: string,
  stream: NodeJS.ReadableStream,
  docker: Docker,
): Promise<BuildResult> => {
  const response = await streamConsumers.text(
    await docker.buildImage(stream, {
      buildargs: {
        BASE_IMAGE: baseImageID,
      },
      networkmode: "none", // no internet access!
      nocache: true, // leave caching to bazel
      forcerm: true, // leave less garbage in case of failure.
    }),
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
    } else {
      lastID = obj.aux.ID;
    }
  }

  if (lastID === undefined)
    throw new Error(`No aux object in response:${response}`);

  return { ok: true, id: lastID };
};

export const buildDockerfile = async (
  dockerfile: string,
  baseImageID: string,
  docker: Docker,
): Promise<BuildResult> => {
  const pack = tar.pack();

  const tarPromise = streamDockerfile(dockerfile, pack);
  const imageIDPromise = build(baseImageID, pack, docker);

  const [buildResult] = await Promise.all([imageIDPromise, tarPromise]);

  return buildResult;
};
