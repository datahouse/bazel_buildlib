import argparse from "argparse";

import { strict as assert } from "node:assert";
import process from "node:process";
import { rename } from "node:fs/promises";
import path from "node:path";
import { execFileWithCode } from "../../js-lib/src/execFileWithCode.js";

interface Config {
  execPaths: string[];
  outDirs: string[];
  cliPath: string;
  queryEngineBinary: string;
  queryEngineLibrary: string;
  schemaEngineBinary: string;
  schemaPath: string;
  binDir: string;
}

const parseArgs = () => {
  const parser = new argparse.ArgumentParser({
    description: "Prisma generator",
  });

  parser.add_argument("--execPath", {
    help: "Additional paths to add to PATH",
    dest: "execPaths",
    action: "append",
    default: [],
  });

  parser.add_argument("--outDir", {
    help: "Output directory",
    required: true,
    dest: "outDirs",
    action: "append",
  });

  parser.add_argument("--cliPath", {
    help: "Path to the Bazel wrapper for the Prisma CLI",
    required: true,
  });

  parser.add_argument("--queryEngineBinary", {
    help: "Path to the Bazel wrapper for the Prisma query engine binary",
    required: true,
  });

  parser.add_argument("--queryEngineLibrary", {
    help: "Path to the Bazel wrapper for the Prisma query engine library",
    required: true,
  });

  parser.add_argument("--schemaEngineBinary", {
    help: "Path to the Bazel wrapper for the Prisma schema engine binary",
    required: true,
  });

  parser.add_argument("--schemaPath", {
    help: "Path to the Prisma schema file",
    required: true,
  });

  parser.add_argument("--binDir", {
    help: "The Bazel bin dir path for the Prisma generate command since that is just a Bazel wrapper",
    required: true,
  });

  return parser.parse_args() as Config;
};

const runPrismaGenerate = ({
  execPaths,
  binDir,
  cliPath,
  schemaPath,
  queryEngineBinary,
  queryEngineLibrary,
  schemaEngineBinary,
}: Config) => {
  const env = {
    ...process.env,
    // do not install @prisma/client
    PRISMA_GENERATE_SKIP_AUTOINSTALL: "True",

    // Prisma engines with paths relative to the Bazel binDir, because the binDir is changed for Prisma generation
    PRISMA_QUERY_ENGINE_BINARY: path.relative(binDir, queryEngineBinary),
    PRISMA_QUERY_ENGINE_LIBRARY: path.relative(binDir, queryEngineLibrary),
    PRISMA_SCHEMA_ENGINE_BINARY: path.relative(binDir, schemaEngineBinary),

    // Set Prisma env variables for unused engines to make sure nothing gets downloaded.
    PRISMA_FMT_BINARY: "unused",
    PRISMA_INTROSPECTION_ENGINE_BINARY: "unused",

    PATH: `${execPaths.join(":")}:${process.env.PATH}`,
    BAZEL_BINDIR: binDir,
  };

  return execFileWithCode(cliPath, ["generate", "--schema", schemaPath], {
    env,
  });
};

const moveToResultDir = (outDir: string): Promise<void> => {
  // The generator did not actually write to the outDir (with .result suffix), but
  // the final output directory. This is intended, so the user config looks clean.
  // However, we need to move it "back" so the individual generator's
  // post-processing steps can claim the real output directory.
  const suffix = ".result";
  assert(outDir.endsWith(suffix));
  const realOutDir = outDir.slice(0, -suffix.length);
  return rename(realOutDir, outDir);
};

const main = async () => {
  const config = parseArgs();
  const { code, stderr } = await runPrismaGenerate(config);
  if (code !== 0) {
    process.stderr.write(stderr);
    process.exit(code);
  }

  await Promise.all(config.outDirs.map(moveToResultDir));
};

await main();
