import { readFile, writeFile } from "node:fs/promises";
import argparse from "argparse";
import { load as loadYaml, dump as dumpYaml } from "js-yaml";

import { ImageInfo, readImageInfos } from "./ImageInfos.js";
import {
  type DockerCompose,
  type ImageInfos,
  patchDcServices,
} from "./patchDcServices.js";

import { OCIImage } from "../../lib/src/OCIImage.js";

const loadImageReference = async (info: ImageInfo) => {
  const {
    manifestDescriptor: { digest },
  } = await OCIImage.load(info.ociDir);

  // stub out the zot registry's address via env var.
  // dc-runner performs the serving and sets the addr in the environment.
  const reference = `\${BAZEL_IMAGE}/${info.zotRepoName}@${digest}`;
  return { reference, ...info };
};

const loadImageInfos = async (infoFile: string): Promise<ImageInfos> => {
  const infos = await readImageInfos(infoFile);
  const withRef = await Promise.all(infos.map(loadImageReference));
  return new Map(withRef.map((info) => [info.imageKey, info]));
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

  return parser.parse_args<{
    input: string;
    output: string;
    imageInfo: string;
  }>();
};

const main = async () => {
  const { imageInfo, input, output } = parseArgs();

  const dc = loadYaml(await readFile(input, "utf8")) as DockerCompose;

  const imageInfos = await loadImageInfos(imageInfo);
  const problemLines = patchDcServices(imageInfos, dc);

  if (problemLines.length > 0) {
    problemLines.forEach((l) => console.error(l));
    process.exit(1);
  }

  await writeFile(output, dumpYaml(dc));
};

await main();
