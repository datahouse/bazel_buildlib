import path from "node:path";
import process from "node:process";

import argparse from "argparse";

// We refer to the path in bazel-bin, so IDE integration works.
const baseConfigPath = "./bazel-bin/eslintrc.dh-defaults.js";

const extendsBaseConfig = (eslintrc: object): boolean => {
  if (!("extends" in eslintrc)) return false;

  const ext = eslintrc.extends;

  switch (typeof ext) {
    case "string":
      return ext === baseConfigPath;
    case "object":
      if (ext instanceof Array) {
        return ext.includes(baseConfigPath);
      }

      return false;
    default:
      return false;
  }
};

const checkEslintrc = (eslintrc: unknown): void => {
  if (typeof eslintrc !== "object" || eslintrc === null)
    throw new Error(`expected exlintrc to be an object, got: ${eslintrc}`);

  if (!extendsBaseConfig(eslintrc)) {
    throw new Error(`.eslintrc must extend ${baseConfigPath}`);
  }
};

const main = async () => {
  const parser = new argparse.ArgumentParser({
    description: "eslintrc config checker",
  });

  parser.add_argument("eslintrc", {
    help: "the renovate eslintrc to check",
  });

  const args = parser.parse_args();

  const eslintrc = await import(path.join(process.cwd(), args.eslintrc));

  checkEslintrc(eslintrc);
};

main().catch((err) => {
  console.log(err);
  process.exit(1);
});
