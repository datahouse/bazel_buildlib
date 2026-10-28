import process from "node:process";
import { pipeline } from "node:stream/promises";
import { createWriteStream } from "node:fs";

import argparse from "argparse";
import { list } from "tar";

import { OCIImage } from "../../lib/src/OCIImage.js";

type PathMatcher = (path: string) => boolean;

const findFileInLayer = async (
  pathMatcher: PathMatcher,
  output: string,
  layerPath: string,
): Promise<boolean> => {
  let result: [string, Promise<void>] | undefined;

  await list({
    strict: true,
    file: layerPath, // note: tar infers (gzip) compression
    noResume: true, // manage stream consumption explicitly.
    onReadEntry: (entry) => {
      const { path, type } = entry;

      if (pathMatcher(path)) {
        if (type !== "File")
          throw new Error(`${path} is not a file but a ${type}`);

        if (result === undefined) {
          result = [path, pipeline(entry, createWriteStream(output))];
        } else {
          const [conflictingPath] = result;
          throw new Error(`regexp matched ${path} and ${conflictingPath}`);
        }
      } else {
        entry.resume(); // skip all data.
      }
    },
  });

  if (result === undefined) return false; // not found

  await result[1];
  return true;
};

const findFileInLayers = async (
  pathMatcher: PathMatcher,
  output: string,
  image: OCIImage,
): Promise<boolean> => {
  const { layers } = image.manifest;

  const revLayers = [...layers];
  revLayers.reverse();

  for (const layer of revLayers) {
    const found = await findFileInLayer(
      pathMatcher,
      output,
      image.blobPath(layer),
    );
    if (found) return true;
  }

  return false;
};

interface Args {
  input: string;
  output: string;
  path?: string;
  regexp?: string;
}

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
  });
  parser.add_argument("--regexp", {
    help: "regex of file to extract from image (passed to new RegExp)",
  });

  return parser.parse_args<Args>();
};

const loadPathMatcher = ({ path, regexp }: Args): PathMatcher => {
  if (path !== undefined && regexp !== undefined)
    throw new Error("may only set one of path / regexp");

  if (path !== undefined) return (got: string) => path === got;

  if (regexp !== undefined) {
    const re = new RegExp(regexp);
    return (got: string) => re.test(got);
  }

  throw new Error("must set one of path / regexp");
};

const main = async () => {
  const args = parseArgs();

  const pathMatcher = loadPathMatcher(args);

  const image = await OCIImage.load(args.input);

  const found = await findFileInLayers(pathMatcher, args.output, image);

  if (!found) {
    process.stderr.write(`Couldn't find expected path in ${args.input}`);
    process.exit(1);
  }
};

await main();
