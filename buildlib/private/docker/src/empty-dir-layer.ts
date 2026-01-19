import { pipeline } from "node:stream/promises";
import { readFile } from "node:fs/promises";
import { createGzip } from "node:zlib";
import { createWriteStream } from "node:fs";

import argparse from "argparse";
import tar from "tar-stream";
import parse_passwd from "parse-passwd";

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

  parser.add_argument("--passwd", {
    help: "passwd file to extract uid / gid from",
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
    passwd: string;
    user: string;
    path: string[];
    output: string;
  };
};

const main = async () => {
  const args = parseArgs();

  const users = parse_passwd(await readFile(args.passwd, "utf8"));
  const userEntry = users.find((p) => p.username === args.user);

  if (!userEntry)
    throw new Error(`couldn't find user ${args.user} in ${args.passwd}`);

  await writeTar(
    args.path,
    parseInt(userEntry.uid, 10),
    parseInt(userEntry.gid, 10),
    args.output,
  );
};

await main();
