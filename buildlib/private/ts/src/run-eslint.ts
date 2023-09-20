import process from "node:process";
import path from "node:path";

/* eslint-disable import/no-duplicates --
 * Allow duplicate import: There is no syntax for namespace and named import in
 * the same line. (This is usually not required, but with the dynamic loading in
 * this module it is).
 */
import type * as eslintModuleNamespaceForType from "eslint";
import type { ESLint } from "eslint";

import argparse from "argparse";

type ESLintModule = typeof eslintModuleNamespaceForType;

// boilerplate reduction utility.
// equivalent to `elems.filter(test)` but allows `test` to be async.
const asyncFilter = async <T>(
  elems: T[],
  test: (e: T) => Promise<boolean>,
): Promise<T[]> => {
  const promises = elems.map(async (e) => ((await test(e)) ? [e] : []));
  const nested = await Promise.all(promises);
  return nested.flat();
};

const parseArgs = () => {
  const parser = new argparse.ArgumentParser({
    description: "eslint runner",
  });

  parser.add_argument("files", {
    help: "the files to lint",
    nargs: "*",
  });

  parser.add_argument("--fix", {
    help: "whether to fix",
    action: "store_true",
  });

  parser.add_argument("--fixTargetName", {
    help: "bazel target name to fix",
    required: true,
  });

  return parser.parse_args() as {
    files: string[];
    fix: boolean;
    fixTargetName: string;
  };
};

/** Change the filePath of the given results using the provided mapper. */
const mapResultsPath = (
  results: ESLint.LintResult[],
  mapper: (p: string) => string,
): ESLint.LintResult[] =>
  results.map((r) => ({ ...r, filePath: mapper(r.filePath) }));

const runLint = async (
  eslint: ESLint,
  files: string[],
): Promise<ESLint.LintResult[]> => {
  const shouldLintFile = async (file: string) =>
    !file.endsWith(".json") && !(await eslint.isPathIgnored(file));

  const filesToLint = await asyncFilter(files, shouldLintFile);

  const rawResults = await eslint.lintFiles(filesToLint);

  return mapResultsPath(rawResults, (p) => path.relative(process.cwd(), p));
};

const hasProblems = (r: ESLint.LintResult): boolean =>
  r.errorCount > 0 || r.fatalErrorCount > 0 || r.warningCount > 0;

const hasFixables = (r: ESLint.LintResult): boolean =>
  r.fixableErrorCount > 0 || r.fixableWarningCount > 0;

const reportResults = async (
  eslint: ESLint,
  results: ESLint.LintResult[],
  fixTargetName: string,
): Promise<void> => {
  const formatter = await eslint.loadFormatter();
  const resultText = formatter.format(results);
  console.log(resultText);

  if (results.findIndex(hasFixables) !== -1) {
    console.log("To fix the fixable results, run:");
    console.log("");
    console.log(`    bazelisk run ${fixTargetName}`);
    console.log("");
  }
};

const fixResults = async (
  eslintMod: ESLintModule,
  results: ESLint.LintResult[],
) => {
  const { BUILD_WORKSPACE_DIRECTORY: workspace } = process.env;

  if (!workspace) {
    throw new Error(
      "Expected BUILD_WORKSPACE_DIRECTORY to be set when --fix is supplied",
    );
  }

  const absResults = mapResultsPath(results, (p) => path.join(workspace, p));

  await eslintMod.ESLint.outputFixes(absResults);
};

const main = async () => {
  const { files, fix, fixTargetName } = parseArgs();

  // load eslint from the project's node_modules (not the one of buildlib).
  const eslintMod: ESLintModule = await import(
    path.join(process.cwd(), "/node_modules/eslint")
  );

  const eslint = new eslintMod.ESLint({ fix });

  const results = await runLint(eslint, files);

  if (fix) {
    await fixResults(eslintMod, results);
  } else {
    await reportResults(eslint, results, fixTargetName);

    const shouldFail = results.findIndex(hasProblems) !== -1;
    if (shouldFail) process.exit(1);
  }
};

main().catch((err) => {
  console.log(err);
  process.exit(2);
});
