import { readFile, writeFile } from "node:fs/promises";
import argparse from "argparse";
import YAML from "js-yaml";

import { ImageInfo, readImageInfos } from "./ImageInfos";

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

const loadImageInfos = async (
  infoFile: string,
): Promise<Map<string, InfoWithReference>> => {
  const infos = await readImageInfos(infoFile);

  const withReference = async ([label, info]: [string, ImageInfo]): Promise<
    [string, InfoWithReference]
  > => {
    if ("reference" in info) return [label, info];

    const digest = await readFile(info.digestFile, "utf8");

    return [label, { reference: digest, ...info }];
  };

  return new Map(await Promise.all(Object.entries(infos).map(withReference)));
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
