import { readFile, writeFile } from "node:fs/promises";

import argparse from "argparse";
import parse_passwd from "parse-passwd";

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
  parser.add_argument("--output", {
    help: "mtree spec output, for the `tar` rule",
  });

  return parser.parse_args<{
    passwd: string;
    user: string;
    path: string[];
    output: string;
  }>();
};

const main = async () => {
  const args = parseArgs();

  const users = parse_passwd(await readFile(args.passwd, "utf8"));
  const userEntry = users.find((p) => p.username === args.user);

  if (!userEntry)
    throw new Error(`couldn't find user ${args.user} in ${args.passwd}`);

  const { uid, gid } = userEntry;

  const lines = args.path.map((p) => {
    const sanitized = p
      .replace(/^\/+/, "") // strip leading `/`
      .replace(/ /g, "\\040"); // replace space with escape
    return `${sanitized} uid=${uid} gid=${gid} time=0 mode=0755 type=dir\n`;
  });

  await writeFile(args.output, lines.join(""));
};

await main();
