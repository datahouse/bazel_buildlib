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

  parser.add_argument("--pnpmVersionFile", {
    help: "bazel's pnpm version",
    required: true,
  });

  parser.add_argument("--latestNodeVersion", {
    help: "rules_nodejs latest known node version",
    required: true,
  });

  return parser.parse_args() as {
    input: string;
    output: string;
    pnpmVersionFile: string;
    latestNodeVersion: string;
  };
};

const main = async () => {
  const { input, output, pnpmVersionFile, latestNodeVersion } = parseArgs();

  const pnpmVersion = JSON.parse(
    await readFile(pnpmVersionFile, "utf8"),
  ).version;

  const curConfig = await readFile(input, "utf8");
  const newConfig = updateConfig(curConfig, { pnpmVersion, latestNodeVersion });

  await writeFile(output, newConfig);
};

await main();
