import path from "node:path";
import process from "node:process";

import argparse from "argparse";

import { readFile } from "node:fs/promises";
import { checkEslintConfig } from "./eslintConfigProblems.js";

const main = async () => {
  const parser = new argparse.ArgumentParser({
    description: "eslint config checker",
  });

  parser.add_argument("config", {
    help: "the eslint config to check",
  });

  const args = parser.parse_args();

  const filePath = path.join(process.cwd(), args.config);
  const eslintConfigRaw = await readFile(filePath, { encoding: "utf8" });
  const problem = checkEslintConfig(eslintConfigRaw);

  if (problem) {
    console.error(problem);
    process.exit(2);
  }
};

await main();
