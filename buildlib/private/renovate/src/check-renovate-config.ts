import fs from "fs/promises";
import path from "path";
import argparse from "argparse";
import JSON5 from "json5";

const readConfig = async (filename: string): Promise<unknown> => {
  const content = await fs.readFile(filename, "utf8");

  switch (path.extname(filename)) {
    case ".json5":
      return JSON5.parse(content);
    case ".json":
      return JSON.parse(content);
    default:
      throw new Error(`unsupported file format ${filename}`);
  }
};

const checkConfig = (config: unknown, pnpmVersion: string): void => {
  if (typeof config !== "object" || config === null)
    throw new Error(`expected config to be an object, got: ${config}`);

  if (!("constraints" in config)) {
    throw new Error(
      `please add 'constraints: { pnpm: "${pnpmVersion}" }' to your renovate config`,
    );
  }

  const { constraints } = config;

  if (typeof constraints !== "object" || constraints === null)
    throw new Error(
      `expected constraints to be an object, got: ${constraints}`,
    );

  if (!("pnpm" in constraints)) {
    throw new Error(
      `please add 'pnpm: "${pnpmVersion}"' to 'constraints' in your renovate config`,
    );
  }

  if (constraints.pnpm !== pnpmVersion) {
    throw new Error(
      `please set constraints.pnpm to "${pnpmVersion}" in your renovate config (got: ${constraints.pnpm})`,
    );
  }
};

const main = async () => {
  const parser = new argparse.ArgumentParser({
    description: "Renovate config checker",
  });

  parser.add_argument("--renovate-config", {
    help: "the renovate config to check",
    required: true,
  });

  parser.add_argument("--pnpm-version", {
    help: "bazel's pnpm version",
    required: true,
  });

  const args = parser.parse_args();

  const config = await readConfig(args.renovate_config);

  checkConfig(config, args.pnpm_version);
};

main().catch((err) => {
  console.log(err);
  process.exit(1);
});
