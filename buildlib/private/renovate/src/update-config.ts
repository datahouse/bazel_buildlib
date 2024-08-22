import { readFile, writeFile } from "node:fs/promises";

import argparse from "argparse";

import { updateConfig } from "./updateConfig.js";

const parseArgs = () => {
  const parser = new argparse.ArgumentParser({
    description: "Renovate config updater",
  });

  parser.add_argument("--input", {
    help: "the renovate config to update",
    required: true,
  });

  parser.add_argument("--output", {
    help: "where to write the updated renovate config",
    required: true,
  });

  parser.add_argument("--pnpmVersion", {
    help: "bazel's pnpm version",
    required: true,
  });

  return parser.parse_args() as {
    input: string;
    output: string;
    pnpmVersion: string;
  };
};

// Taken from:
// https://github.com/bazelbuild/rules_nodejs/blob/v6.2.0/nodejs/private/node_versions.bzl
//
// TODO: Expose in rules_nodejs and inject from there so we do not need to keep
// it up to date manually (filed as #689).
const newestNodeVersion = "20.14.0";

const main = async () => {
  const { input, output, pnpmVersion } = parseArgs();

  const curConfig = await readFile(input, "utf8");
  const newConfig = updateConfig(curConfig, { pnpmVersion, newestNodeVersion });

  await writeFile(output, newConfig);
};

await main();
