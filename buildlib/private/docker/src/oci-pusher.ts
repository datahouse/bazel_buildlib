import { readFile } from "node:fs/promises";

import process from "node:process";

import argparse from "argparse";

import spawnInheritIO from "./spawnInheritIO.js";

import { inferRepositoryPrefix } from "./repoPrefix.js";

const parseArgs = (args: string[]) => {
  const parser = new argparse.ArgumentParser({
    description: "Multi OCI image pusher",
  });

  parser.add_argument("--dry-run", {
    help: "Only show commands, don't run",
    action: argparse.BooleanOptionalAction,
    default: false,
  });

  return parser.parse_args(args) as {
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
  // Ignore first 2 args:
  // - The name of the node binary
  // - The path to the JS script.
  const [, , cranePath, stamp, tagFile, imageInfoFile, ...userArgs] =
    process.argv;

  const { dry_run: dryRun } = parseArgs(userArgs);

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
    const exitCodes = await Promise.all(
      commands.map((cmd) => spawnInheritIO(cranePath, ...cmd)),
    );

    if (exitCodes.every((c) => c === 0)) {
      process.exit(0);
    }

    // Just exit non-zero, the failing crane command will have reported a problem.
    process.exit(1);
  }
};

await main();
