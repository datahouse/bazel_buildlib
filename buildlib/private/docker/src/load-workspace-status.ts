import fs from "fs/promises";
import path from "path";
import argparse from "argparse";

import parseWorkspaceStatus from "../../js-lib/src/parseWorkspaceStatus";

const writeStatus = async (filename: string, data: Map<string, string>) => {
  const name = path.basename(filename);

  const v = data.get(name);

  if (v === undefined) {
    throw new Error(
      `couldn't find workspace status ${name}, did you set --workspace_status_command`,
    );
  }

  await fs.writeFile(filename, v, "utf8");
};

const parseArgs = () => {
  const parser = new argparse.ArgumentParser({
    description: "Bazel workspace status loader",
  });

  parser.add_argument("--info-file", {
    help: "workspace status info file (ctx.info_file)",
    required: true,
  });
  parser.add_argument("outputs", {
    help: "Output files, basename must be var name",
    nargs: "*",
  });

  return parser.parse_args() as {
    info_file: string;
    outputs: string[];
  };
};

const main = async () => {
  const args = parseArgs();

  const rawStatus = await fs.readFile(args.info_file, "utf8");

  const status = parseWorkspaceStatus(rawStatus);

  await Promise.all(args.outputs.map((f) => writeStatus(f, status)));
};

main().catch((err) => {
  console.log(err);
  process.exit(1);
});
