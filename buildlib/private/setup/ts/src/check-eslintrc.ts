import path from "node:path";
import process from "node:process";

import argparse from "argparse";

import { checkEslintrc } from "./eslintrcProblems.js";

const main = async () => {
  const parser = new argparse.ArgumentParser({
    description: "eslintrc config checker",
  });

  parser.add_argument("eslintrc", {
    help: "the renovate eslintrc to check",
  });

  const args = parser.parse_args();

  const eslintrcMod = await import(path.join(process.cwd(), args.eslintrc));
  const rawEslintrc = eslintrcMod.default as unknown;

  const problems = checkEslintrc(rawEslintrc);

  if (problems.length > 0) {
    console.error("There are problems with your .eslintrc:");
    problems.forEach((p) => console.error(`- ${p}`));
    process.exit(2);
  }
};

await main();
