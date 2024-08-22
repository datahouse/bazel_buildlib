import argparse from "argparse";
import tar from "tar-stream";
import Docker from "dockerode";

import path from "node:path";
import { createWriteStream } from "node:fs";
import { mkdir } from "node:fs/promises";
import { pipeline } from "node:stream/promises";

import { loadImageDirToDocker } from "./loadImageToDocker.js";
import { buildDockerfile } from "./buildDockerfile.js";

const parseArgs = () => {
  const parser = new argparse.ArgumentParser({
    description: "Dockerfile builder",
  });

  parser.add_argument("--dockerfile", {
    help: "Dockerfile to build",
    required: true,
  });
  parser.add_argument("--outputDir", {
    help: "Output directory where OCI image is put",
    required: true,
  });
  parser.add_argument("--baseImage", {
    help: "OCI directory containing the base image",
    required: true,
  });

  return parser.parse_args() as {
    dockerfile: string;
    outputDir: string;
    baseImage: string;
  };
};

const storeImageToDir = async (
  imageID: string,
  outputDir: string,
  docker: Docker,
) => {
  const imageTarStream = await docker.getImage(imageID).get();

  await mkdir(outputDir, { recursive: true });

  const extract = tar.extract();

  const pipe = pipeline(imageTarStream, extract);

  for await (const entry of extract) {
    const { type, name } = entry.header;

    if (type === "file") {
      await mkdir(path.join(outputDir, path.dirname(name)), {
        recursive: true,
      });
      await pipeline(entry, createWriteStream(path.join(outputDir, name)));
    }
  }

  await pipe;
};

const main = async () => {
  const { dockerfile, outputDir, baseImage } = parseArgs();

  const docker = new Docker();

  const baseImageID = await loadImageDirToDocker(baseImage);
  const imageID = await buildDockerfile(
    dockerfile,
    baseImageID,
    docker,
    console.log,
  );
  await storeImageToDir(imageID, outputDir, docker);
};

await main();
