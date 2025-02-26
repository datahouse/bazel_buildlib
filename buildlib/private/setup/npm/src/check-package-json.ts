import process from "node:process";
import { readFile } from "node:fs/promises";
import argparse from "argparse";
import { packageJsonProblems } from "./packageJsonProblems.js";

const main = async () => {
  const parser = new argparse.ArgumentParser({
    description: "package.json checker",
  });
  parser.add_argument("package_json", {
    help: "the package.json to check",
  });
  const args = parser.parse_args();
  const pkgContent = await readFile(args.package_json, "utf8");
  const parsedPkg = JSON.parse(pkgContent);
  const problems = packageJsonProblems(parsedPkg);
  if (problems.length > 0) {
    console.error("There are problems with your package.json");
    problems.forEach((message) => {
      console.error(`- ${message}`);
    });
    process.exit(2);
  }
};

await main();
