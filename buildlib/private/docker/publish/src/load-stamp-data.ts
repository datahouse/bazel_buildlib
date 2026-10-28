import { writeFile } from "node:fs/promises";

import argparse from "argparse";

import { loadWorkspaceStatus } from "../../../js-lib/src/loadWorkspaceStatus.js";

const parseArgs = () => {
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
  parser.add_argument("--buildTimeFile", {
    help: "file to write build time to",
    required: true,
  });
  parser.add_argument("--tagFile", {
    help: "file to write docker tag to",
    required: true,
  });

  return parser.parse_args<{
    stableStatusFile: string;
    buildTimeFile: string;
    volatileStatusFile: string;
    tagFile: string;
  }>();
};

const main = async () => {
  const { stableStatusFile, volatileStatusFile, buildTimeFile, tagFile } =
    parseArgs();

  const { tag, buildTime } = await loadWorkspaceStatus(
    stableStatusFile,
    volatileStatusFile,
  );

  await writeFile(tagFile, tag);
  await writeFile(buildTimeFile, buildTime.toISOString());
};

await main();
