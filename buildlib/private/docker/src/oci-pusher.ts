import { readFile } from "node:fs/promises";

import process from "node:process";

import argparse from "argparse";

import spawnInheritIO from "./spawnInheritIO.js";

import { inferRepositoryPrefix } from "./repoPrefix.js";

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
  parser.add_argument("--imageInfoFile", {
    help: "File with info about images to push",
    required: true,
  });
  parser.add_argument("--dry-run", {
    help: "Only show commands, don't run",
    action: argparse.BooleanOptionalAction,
    default: false,
  });

  return parser.parse_args() as {
    cranePath: string;
    stamp: string;
    tagFile: string;
    imageInfoFile: string;
    dry_run: boolean;
  };
};

const tagRE = /^\S+$/; // check non-empty, no whitespace

const loadTag = async (tagFile: string) => {
  const tag = (await readFile(tagFile, "utf8")).trim();

  if (!tagRE.test(tag)) throw new Error(`invalid tag: '${tag}'`);

  return tag;
};

const main = async () => {
  const {
    cranePath,
    stamp,
    tagFile,
    imageInfoFile,
    dry_run: dryRun,
  } = parseArgs();

  if (stamp !== "true")
    throw new Error(
      "Refusing to push an unstamped build. Did you forget to set --stamp?",
    );

  const repositoryPrefix = inferRepositoryPrefix(process.env);

  const tag = await loadTag(tagFile);

  const imageInfos = JSON.parse(
    await readFile(imageInfoFile, "utf8"),
  ) as Record<string, string>;

  const commands = Object.entries(imageInfos).map(([repository, ociDir]) => [
    "push",
    ociDir,
    `${repositoryPrefix}/${repository}:${tag}`,
  ]);

  if (dryRun) {
    console.log("dh_docker_images_push would run:", commands);
  } else {
    await Promise.all(commands.map((cmd) => spawnInheritIO(cranePath, ...cmd)));
  }
};

await main();
