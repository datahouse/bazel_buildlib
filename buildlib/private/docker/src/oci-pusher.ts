import process from "node:process";

import { readFile } from "node:fs/promises";

import argparse from "argparse";

import spawnInheritIO from "./spawnInheritIO.js";

const parseArgs = () => {
  const parser = new argparse.ArgumentParser({
    description: "Multi OCI image pusher",
  });

  parser.add_argument("--cranePath", {
    help: "Crane binary to use",
    required: true,
  });
  parser.add_argument("--stamp", {
    help: "Whether the build is running under stamp",
    required: true,
  });
  parser.add_argument("--tagFile", {
    help: "File with tag to push",
    required: true,
  });
  parser.add_argument("--repositoryPrefix", {
    help: "Prefix of repository to push to",
    required: true,
  });
  parser.add_argument("--imageInfoFile", {
    help: "File with info about images to push",
    required: true,
  });

  return parser.parse_args() as {
    cranePath: string;
    stamp: string;
    tagFile: string;
    repositoryPrefix: string;
    imageInfoFile: string;
  };
};

const tagRE = /^\S+$/; // check non-empty, no whitespace

const loadTag = async (tagFile: string) => {
  const tag = (await readFile(tagFile, "utf8")).trim();

  if (!tagRE.test(tag)) throw new Error(`invalid tag: '${tag}'`);

  return tag;
};

const main = async () => {
  const { cranePath, stamp, tagFile, repositoryPrefix, imageInfoFile } =
    parseArgs();

  if (stamp !== "true")
    throw new Error(
      "Refusing to push an unstamped build. Did you forget to set --stamp?",
    );

  const tag = await loadTag(tagFile);

  const imageInfos = JSON.parse(
    await readFile(imageInfoFile, "utf8"),
  ) as Record<string, string>;

  await Promise.all(
    Object.entries(imageInfos).map(([repository, ociDir]) =>
      spawnInheritIO(
        cranePath,
        "push",
        ociDir,
        `${repositoryPrefix}/${repository}:${tag}`,
      ),
    ),
  );
};

main().catch((err) => {
  console.log(err);
  process.exit(1);
});
