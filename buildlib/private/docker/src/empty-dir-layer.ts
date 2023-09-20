import assert from "node:assert/strict";
import { Readable } from "node:stream";
import { pipeline } from "node:stream/promises";
import { createGzip, createGunzip } from "node:zlib";
import { createWriteStream, createReadStream } from "node:fs";

import argparse from "argparse";
import tar from "tar-stream";
import parse_passwd from "parse-passwd";
import { WritableStreamBuffer } from "stream-buffers";

const readStreamToString = async (stream: Readable): Promise<string> => {
  const buf = new WritableStreamBuffer();

  await pipeline(stream, buf);

  // getContentsAsString returns false if the buffer is size 0.
  // This is a normal condition, so we simply replace by the empty string.
  return buf.getContentsAsString("utf8") || "";
};

const findFileInLayer = async (
  name: string,
  layer: string,
): Promise<string | undefined> => {
  const extract = tar.extract();

  let result: Promise<string> | undefined;

  extract.on("entry", (header, stream, next) => {
    stream.on("end", () => next());

    if (header.name === name) {
      assert(result === undefined);
      result = readStreamToString(stream);
    } else {
      stream.resume(); // skip all data.
    }
  });

  await pipeline(createReadStream(layer), createGunzip(), extract);

  return result;
};

const findFileInLayers = async (
  name: string,
  layers: string[],
): Promise<string> => {
  const revLayers = [...layers];
  revLayers.reverse();

  for (const layer of revLayers) {
    const result = await findFileInLayer(name, layer);
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

const main = async () => {
  const parser = new argparse.ArgumentParser({
    description:
      "Builder for layer with empty, writeable directories (for volumes)",
  });

  parser.add_argument("--layer", {
    help: "layers of the base image (to find uid / gid)",
    nargs: "*",
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

  const args = parser.parse_args();

  const passwdRaw = await findFileInLayers("etc/passwd", args.layer);
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
