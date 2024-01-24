import { readFile, writeFile } from "node:fs/promises";
import argparse from "argparse";
import YAML from "js-yaml";

import { ImageInfo, readImageInfos } from "./ImageInfos.js";

import { OCIImage } from "./OCIImage.js";

type InfoWithReference = ImageInfo & { reference: string };

interface Service {
  "bazel-image"?: string;
  image?: string;
  volumes?: string[];
}

interface DockerCompose {
  services: {
    [name: string]: Service;
  };
}

const loadImageReference = async (
  info: ImageInfo,
): Promise<InfoWithReference> => {
  const image = await OCIImage.load(info.ociDir);

  const shaPrefix = "sha256:";

  const { config } = image.manifest;

  if (!config.digest.startsWith(shaPrefix))
    throw new Error("unsupported digest");

  const reference = config.digest.slice(shaPrefix.length);

  return { reference, ...info };
};

const loadImageInfos = async (
  infoFile: string,
): Promise<Map<string, InfoWithReference>> => {
  const infos = await readImageInfos(infoFile);
  const withRef = await Promise.all(infos.map(loadImageReference));
  return new Map(withRef.flatMap((info) => info.keys.map((k) => [k, info])));
};

const patchService = (
  imageInfos: Map<string, InfoWithReference>,
  name: string,
  service: Service,
): void => {
  const label = service["bazel-image"];

  if (!label) return; // not a bazel managed image.

  if (service.image)
    throw new Error(`got both bazel-image and image for service ${name}`);

  const info = imageInfos.get(label);
  if (!info) {
    throw new Error(
      `couldn't find label ${label} for service ${name}. Did you declare the label it in deps?`,
    );
  }

  delete service["bazel-image"];
  service.image = info.reference;

  if (!("hotReload" in info) || !info.hotReload) return;

  const { hostHomePath, containerPath } = info.hotReload;

  if (!service.volumes) service.volumes = [];

  service.volumes.push(`$HOME/${hostHomePath}:${containerPath}:ro`);
};

const main = async () => {
  const parser = new argparse.ArgumentParser({
    description: "Bazel docker-compose.yml processor",
  });

  parser.add_argument("--input", { help: "Input docker-compose.yml" });
  parser.add_argument("--output", { help: "Output docker-compose.yml" });
  parser.add_argument("--imageInfo", {
    help: "image-info.json mapping labels to digest files",
  });
  const args = parser.parse_args();

  const imageInfos = await loadImageInfos(args.imageInfo);
  const dc = YAML.load(await readFile(args.input, "utf8")) as DockerCompose;

  // Replace images that have bazel labels (mutably in dc).
  Object.entries(dc.services).forEach(([name, service]) =>
    patchService(imageInfos, name, service),
  );

  await writeFile(args.output, YAML.dump(dc));
};

main().catch((err) => {
  console.log(err);
  process.exit(1);
});
