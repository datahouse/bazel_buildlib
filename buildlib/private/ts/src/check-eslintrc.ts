import path from "node:path";
import process from "node:process";

import argparse from "argparse";

import { z } from "zod";

// We refer to the path in bazel-bin, so IDE integration works.
const baseConfigPath = "./bazel-bin/eslintrc.dh-defaults.cjs";

const eslintrcSchema = z
  .object({
    root: z.boolean(),
    extends: z.union([z.string(), z.array(z.string())]),
  })
  .partial();

type Eslintrc = z.infer<typeof eslintrcSchema>;

const extendsBaseConfig = (ext: Eslintrc["extends"]): boolean => {
  if (ext === baseConfigPath) return true;
  if (ext instanceof Array) return ext.includes(baseConfigPath);
  return false;
};

const checkEslintrc = (eslintrc: Eslintrc): string[] => {
  const problems = [];

  if (!extendsBaseConfig(eslintrc.extends))
    problems.push(`.eslintrc must extend ${baseConfigPath}`);

  // See [no-sandbox] at the bottom for why we need this.
  if (eslintrc.root !== true)
    problems.push("You must set `root: true` in .eslintrc");

  return problems;
};

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
  const eslintrc = eslintrcSchema.parse(rawEslintrc);

  const problems = checkEslintrc(eslintrc);

  if (problems.length > 0) {
    console.error("There are problems with your .eslintrc:");
    problems.forEach((p) => console.error(`- ${p}`));
    process.exit(2);
  }
};

await main();

/* [no-sandbox]
 *
 * We require `root: true` to avoid that eslint finds the same .eslintrc.js
 * twice when running without sandboxing.
 *
 * If sandboxing is off, it will find it:
 *
 * 1. Once under bazel-out/... (the one we want)
 * 2. Once the source file itself (which is a sibling to bazel-out).
 *
 * By default, eslint attempts to merge .eslintrc.js files. However, when
 * it finds the second one, it cannot find the files it attempts to
 * include (./bazel-bin/eslintrc.dh-defaults.js) and fails.
 *
 * This does not happen in the sandbox, because the source file is not
 * made part of the sandbox.
 *
 * We care about running eslint outside the sandbox since it will allow
 * us to run it with --fix.
 */
