import { writeFile } from "node:fs/promises";

import argparse from "argparse";

import { loadWorkspaceStatus } from "../../js-lib/src/loadWorkspaceStatus.js";

const main = async () => {
  const parser = new argparse.ArgumentParser({
    description: "Bazel workspace status loader",
  });

  parser.add_argument("--stableStatusFile", {
    help: "stable workspace status file",
    required: true,
  });
  parser.add_argument("--volatileStatusFile", {
    help: "volatile workspace status file",
    required: true,
  });
  parser.add_argument("--output", {
    help: "output filename",
    required: true,
  });

  const args = parser.parse_args<{
    stableStatusFile: string;
    volatileStatusFile: string;
    output: string;
  }>();

  const { commit, tag } = await loadWorkspaceStatus(
    args.stableStatusFile,
    args.volatileStatusFile,
  );

  const myVersion = `${tag}+${commit}`;

  await writeFile(args.output, myVersion, "utf8");
};

await main();
