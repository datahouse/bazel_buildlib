import process from "node:process";

import { readFile, writeFile } from "node:fs/promises";

import argparse from "argparse";

import { updatePnpmWorkspace } from "./updatePnpmWorkspace.js";

const parseArgs = () => {
  const parser = new argparse.ArgumentParser();
  parser.add_argument("infile");
  parser.add_argument("outfile");

  return parser.parse_args<{
    infile: string;
    outfile: string;
  }>();
};

const main = async () => {
  const { infile, outfile } = parseArgs();

  const current = await readFile(infile, "utf8");
  const result = updatePnpmWorkspace(current);

  if ("problems" in result) {
    console.error("There are problems with your pnpm-workspace.yaml:");
    result.problems.forEach((message) => {
      console.error(`- ${message}`);
    });
    process.exit(2);
  }

  await writeFile(outfile, result.updated);
};

await main();
