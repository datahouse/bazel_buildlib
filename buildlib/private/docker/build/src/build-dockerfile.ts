import argparse from "argparse";
import { extract } from "tar";
import Docker from "dockerode";

import process from "node:process";
import { pipeline } from "node:stream/promises";

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

  return parser.parse_args<{
    dockerfile: string;
    outputDir: string;
    baseImage: string;
  }>();
};

const main = async () => {
  const { dockerfile, outputDir, baseImage } = parseArgs();

  const docker = new Docker();

  const buildResult = await buildDockerfile(dockerfile, baseImage, docker);

  if (!buildResult.ok) {
    console.log(buildResult.error);
    process.exit(1);
  }

  const resultImageTarStream = await docker.getImage(buildResult.id).get();
  await pipeline(
    resultImageTarStream,
    extract({ cwd: outputDir, strict: true }),
  );
};

await main();
