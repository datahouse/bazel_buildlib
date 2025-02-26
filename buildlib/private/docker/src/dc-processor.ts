import { readFile, writeFile } from "node:fs/promises";
import argparse from "argparse";
import YAML from "js-yaml";

import { ImageInfo, readImageInfos } from "./ImageInfos.js";
import {
  type DockerCompose,
  type ImageInfos,
  patchDcServices,
  patchDcServicesFake,
} from "./patchDcServices.js";

import { OCIImage } from "./OCIImage.js";

const loadImageReference = async (info: ImageInfo) => {
  const image = await OCIImage.load(info.ociDir);

  const shaPrefix = "sha256:";

  const { config } = image.manifest;

  if (!config.digest.startsWith(shaPrefix))
    throw new Error("unsupported digest");

  const reference = config.digest.slice(shaPrefix.length);

  return { reference, ...info };
};

const loadImageInfos = async (infoFile: string): Promise<ImageInfos> => {
  const infos = await readImageInfos(infoFile);
  const withRef = await Promise.all(infos.map(loadImageReference));
  return new Map(withRef.flatMap((info) => info.keys.map((k) => [k, info])));
};

const parseArgs = () => {
  const parser = new argparse.ArgumentParser({
    description: "Bazel docker-compose.yml processor",
  });

  parser.add_argument("--input", { help: "Input docker-compose.yml" });
  parser.add_argument("--output", { help: "Output docker-compose.yml" });
  parser.add_argument("--imageInfo", {
    help: "image-info.json mapping labels to digest files",
  });
  parser.add_argument("--fake", {
    help: "image-info.json mapping labels to digest files",
    action: argparse.BooleanOptionalAction,
    default: false,
  });

  return parser.parse_args() as {
    input: string;
    output: string;
    imageInfo: string;
    fake: boolean;
  };
};

const main = async () => {
  const { imageInfo, input, output, fake } = parseArgs();

  const dc = YAML.load(await readFile(input, "utf8")) as DockerCompose;

  if (fake) {
    patchDcServicesFake(dc);
  } else {
    const imageInfos = await loadImageInfos(imageInfo);
    const problemLines = patchDcServices(imageInfos, dc);

    if (problemLines.length > 0) {
      problemLines.forEach((l) => console.error(l));
      process.exit(1);
    }
  }

  await writeFile(output, YAML.dump(dc));
};

await main();
