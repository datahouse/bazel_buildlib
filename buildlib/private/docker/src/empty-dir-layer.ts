import assert from "node:assert/strict";

import { Readable } from "node:stream";
import { pipeline } from "node:stream/promises";
import { createGzip, createGunzip } from "node:zlib";
import { createWriteStream } from "node:fs";
import streamConsumers from "node:stream/consumers";

import argparse from "argparse";
import tar from "tar-stream";
import parse_passwd from "parse-passwd";

import { LayerFormat, OCIImage, Descriptor } from "./OCIImage.js";

type LayerPipe = (r: Readable, w: tar.Extract) => Promise<void>;

const layerPipes: Record<LayerFormat, LayerPipe> = {
  tar: (r, w) => pipeline(r, w),
  "tar+gzip": (r, w) => pipeline(r, createGunzip(), w),
};

const findFileInLayer = async (
  name: string,
  image: OCIImage,
  layer: Descriptor,
): Promise<string | undefined> => {
  const extract = tar.extract();

  let result: Promise<string> | undefined;

  extract.on("entry", (header, stream, next) => {
    stream.on("end", () => next());

    if (header.name === name) {
      assert(result === undefined);
      result = streamConsumers.text(stream);
    } else {
      stream.resume(); // skip all data.
    }
  });

  const pipeLayer = layerPipes[OCIImage.layerFormat(layer)];
  await pipeLayer(image.read(layer), extract);

  return result;
};

const findFileInLayers = async (
  name: string,
  image: OCIImage,
): Promise<string> => {
  const { layers } = image.manifest;

  const revLayers = [...layers];
  revLayers.reverse();

  for (const layer of revLayers) {
    const result = await findFileInLayer(name, image, layer);
    if (result !== undefined) return result;
  }

  throw new Error(`couldn't find ${name} in image layers`);
};

const writeTar = async (
  paths: string[],
  uid: number,
  gid: number,
  output: string,
): Promise<void> => {
  const pkg = tar.pack();
  const pipe = pipeline(pkg, createGzip(), createWriteStream(output));

  const mtime = new Date(0);

  paths.forEach((name) =>
    pkg
      .entry({
        type: "directory",
        name,
        uid,
        gid,
        mtime,
      })
      .end(),
  );

  pkg.finalize();

  await pipe;
};

const parseArgs = () => {
  const parser = new argparse.ArgumentParser({
    description:
      "Builder for layer with empty, writeable directories (for volumes)",
  });

  parser.add_argument("--base", {
    help: "directory of the base image (to find uid / gid)",
    required: true,
  });
  parser.add_argument("--user", {
    help: "user to own the directories (group will be primary group of this user)",
    required: true,
  });
  parser.add_argument("--path", {
    help: "paths to create",
    nargs: "*",
    required: true,
  });
  parser.add_argument("--output", { help: "tar output (.tar.gz)" });

  return parser.parse_args() as {
    base: string;
    user: string;
    path: string[];
    output: string;
  };
};

const main = async () => {
  const args = parseArgs();

  const image = await OCIImage.load(args.base);

  const passwdRaw = await findFileInLayers("etc/passwd", image);
  const userEntry = parse_passwd(passwdRaw).find(
    (p) => p.username === args.user,
  );

  if (!userEntry)
    throw new Error(`couldn't find user ${args.user} in base image`);

  await writeTar(
    args.path,
    parseInt(userEntry.uid, 10),
    parseInt(userEntry.gid, 10),
    args.output,
  );
};

main().catch((err) => {
  console.log(err);
  process.exit(1);
});
