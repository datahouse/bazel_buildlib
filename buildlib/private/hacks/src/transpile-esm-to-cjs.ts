import {
  mkdir,
  readdir,
  copyFile,
  readFile,
  writeFile,
} from "node:fs/promises";

import path from "node:path";
import process from "node:process";

import argparse from "argparse";

import { transformFileAsync, TransformOptions } from "@babel/core";

import ModuleResolverPlugin from "babel-plugin-module-resolver";
import TransformModulesCommonJSPlugin from "@babel/plugin-transform-modules-commonjs";

const esmExtensions = new Map([
  [".mts", ".ts"],
  [".mjs", ".js"],
]);

const removeESMExtension = (inPath: string) => {
  const { ext, name, dir } = path.parse(inPath);

  const newExt = esmExtensions.get(ext);

  if (newExt === undefined) {
    return inPath;
  }

  return path.format({ dir, name, ext: newExt });
};

/* A note about the usage of babel:
 * Of course it would be much nicer to use SWC here to avoid having another transpiler in the mix.
 * However, it seems (at the time of writing), SWC does not have the equivalent of the ModuleResolverPlugin.
 * Therefore, we'd need another transpiler (like bable) anyways, so we might as well use a single one.
 */
const makeBabelOptions = (
  replacements: Map<string, string>,
): TransformOptions => ({
  plugins: [
    [
      ModuleResolverPlugin,
      {
        resolvePath(sourcePath: string) {
          const replaced = replacements.get(sourcePath);

          if (replaced !== undefined) {
            return replaced;
          }

          if (sourcePath.startsWith("./")) {
            return removeESMExtension(sourcePath);
          }

          return sourcePath;
        },
      },
    ],
    TransformModulesCommonJSPlugin,
  ],
});

interface TransformedConfig {
  main?: string;
}

const processPackageJson = async (inPath: string, outPath: string) => {
  const input: unknown = JSON.parse(await readFile(inPath, "utf8"));

  if (!(input instanceof Object)) {
    throw new Error(
      `expected package.json to contain an Object, got: ${input}`,
    );
  }

  const out: TransformedConfig = {};

  if ("main" in input && typeof input.main === "string") {
    out.main = removeESMExtension(input.main);
  }

  await writeFile(outPath, JSON.stringify(out));
};

const transpile = async (
  inPath: string,
  outPath: string,
  babelOptions: TransformOptions,
) => {
  const result = await transformFileAsync(inPath, babelOptions);

  if (result === null || result.code == null)
    throw new Error(`no babel result for ${inPath}`);

  await mkdir(path.dirname(outPath), { recursive: true });
  await writeFile(outPath, result.code);
};

const processFile = async (
  baseDir: string,
  outDir: string,
  babelOptions: TransformOptions,
  filePath: string,
): Promise<void> => {
  const inPath = path.join(baseDir, filePath);
  const outPath = path.join(outDir, removeESMExtension(filePath));

  if (filePath === "package.json") {
    await processPackageJson(inPath, outPath);
  } else if (outPath.endsWith(".d.ts")) {
    await mkdir(path.dirname(outPath), { recursive: true });
    await copyFile(inPath, outPath);
  } else if (outPath.endsWith(".js")) {
    await transpile(inPath, outPath, babelOptions);
  }
};

const parseArgs = () => {
  const parser = new argparse.ArgumentParser({
    description: "node_module transpiler",
  });

  parser.add_argument("--outdir", {
    help: "output directory",
    required: true,
  });

  parser.add_argument("--indir", {
    help: "dir to transpile",
    required: true,
  });

  const parseReplace = (r: string): [string, string] => {
    const p = r.split("=");

    if (p.length !== 2) throw new Error(`bad argument to --replace: ${r}`);

    return [p[0], p[1]];
  };

  parser.add_argument("--replace", {
    help: "module overrides",
    nargs: "*",
    type: parseReplace,
  });

  return parser.parse_args() as {
    outdir: string;
    indir: string;
    replace: [string, string][];
  };
};

const main = async () => {
  const { outdir, indir, replace } = parseArgs();

  await mkdir(outdir, { recursive: true });

  const files = await readdir(indir, { recursive: true });

  const babelOptions = makeBabelOptions(new Map(replace));

  await Promise.all(
    files.map((f) => processFile(indir, outdir, babelOptions, f)),
  );
};

main().catch((err) => {
  console.log(err);
  process.exit(1);
});
