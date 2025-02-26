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

// NOTE:
// We avoid using zod's internal safeParse method here.
// - Using safeParse for .eslintrc validation with custom error messages decreases maintainability (see #911)
// - (ab)using safeParse is effective for package.json validation (see #801) due to its simpler structure and validation needs
export const checkEslintrc = (rawEslintrc: unknown): string[] => {
  const eslintrc = eslintrcSchema.parse(rawEslintrc);
  const problems = [];

  if (!extendsBaseConfig(eslintrc.extends))
    problems.push(`.eslintrc must extend ${baseConfigPath}`);

  // See [no-sandbox] at the bottom for why we need this.
  if (eslintrc.root !== true)
    problems.push("You must set `root: true` in .eslintrc");

  return problems;
};

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
