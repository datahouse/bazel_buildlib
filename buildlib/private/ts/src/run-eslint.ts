import process from "node:process";
import path from "node:path";

import type { ESLint } from "eslint";

import argparse from "argparse";

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

// load eslint from the project's node_modules (not the one of buildlib).
const loadESLint = async (): Promise<ESLint> => {
  const eslintModule = await import(
    path.join(process.cwd(), "/node_modules/eslint")
  );
  return new eslintModule.ESLint();
};

const printResults = async (
  eslint: ESLint,
  results: ESLint.LintResult[],
): Promise<void> => {
  const formatter = await eslint.loadFormatter();
  const resultText = formatter.format(results);
  console.log(resultText);
};

const hasProblems = (r: ESLint.LintResult): boolean =>
  r.errorCount > 0 || r.fatalErrorCount > 0 || r.warningCount > 0;

const main = async () => {
  const parser = new argparse.ArgumentParser({
    description: "eslint runner",
  });

  parser.add_argument("files", {
    help: "the files to lint",
    nargs: "*",
  });

  const args = parser.parse_args();

  const eslint = await loadESLint();

  const shouldLintFile = async (file: string) =>
    !file.endsWith(".json") && !(await eslint.isPathIgnored(file));

  const filesToLint = await asyncFilter(args.files, shouldLintFile);

  const results = await eslint.lintFiles(filesToLint);

  await printResults(eslint, results);

  const shouldFail = results.findIndex(hasProblems) !== -1;
  if (shouldFail) process.exit(1);
};

main().catch((err) => {
  console.log(err);
  process.exit(2);
});
