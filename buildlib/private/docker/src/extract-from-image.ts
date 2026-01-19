import assert from "node:assert/strict";

import process from "node:process";
import { Readable } from "node:stream";
import { pipeline } from "node:stream/promises";
import { createGunzip } from "node:zlib";
import { createWriteStream } from "node:fs";

import argparse from "argparse";
import tar from "tar-stream";

import { LayerFormat, OCIImage, Descriptor } from "./OCIImage.js";

type LayerPipe = (r: Readable, w: tar.Extract) => Promise<void>;

const layerPipes: Record<LayerFormat, LayerPipe> = {
  tar: (r, w) => pipeline(r, w),
  "tar+gzip": (r, w) => pipeline(r, createGunzip(), w),
};

const findFileInLayer = async (
  path: string,
  output: string,
  image: OCIImage,
  layer: Descriptor,
): Promise<boolean> => {
  const extract = tar.extract();

  let result: Promise<void> | undefined;

  extract.on("entry", ({ name, type }, stream, next) => {
    stream.on("end", () => next());

    if (name === path) {
      assert(result === undefined);
      if (type !== "file")
        throw new Error(`${path} is not a file but a ${type}`);
      result = pipeline(stream, createWriteStream(output));
    } else {
      stream.resume(); // skip all data.
    }
  });

  const pipeLayer = layerPipes[OCIImage.layerFormat(layer)];
  await pipeLayer(image.read(layer), extract);

  if (result === undefined) return false; // not found

  await result;
  return true;
};

const findFileInLayers = async (
  path: string,
  output: string,
  image: OCIImage,
): Promise<boolean> => {
  const { layers } = image.manifest;

  const revLayers = [...layers];
  revLayers.reverse();

  for (const layer of revLayers) {
    const found = await findFileInLayer(path, output, image, layer);
    if (found) return true;
  }

  return false;
};

const parseArgs = () => {
  const parser = new argparse.ArgumentParser({
    description: "OCI image file extractor",
  });

  parser.add_argument("--input", {
    help: "directory of the image to extract from",
    required: true,
  });
  parser.add_argument("--output", {
    help: "path to write file to",
    required: true,
  });
  parser.add_argument("--path", {
    help: "path of file to extract from image (no leading slash)",
    required: true,
  });

  return parser.parse_args() as {
    input: string;
    output: string;
    path: string;
  };
};

const main = async () => {
  const { input, output, path } = parseArgs();

  const image = await OCIImage.load(input);

  const found = await findFileInLayers(path, output, image);

  if (!found) {
    process.stderr.write(`Couldn't find file ${path} in ${input}`);
    process.exit(1);
  }
};

await main();
