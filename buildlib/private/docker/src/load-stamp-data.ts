import { readFile, writeFile } from "node:fs/promises";

import argparse from "argparse";

import parseWorkspaceStatus from "../../js-lib/src/parseWorkspaceStatus.js";
import { labelsForStatus } from "./imageLabels.js";

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
  parser.add_argument("--labelsFile", {
    help: "file to write docker labels to",
    required: true,
  });
  parser.add_argument("--tagFile", {
    help: "file to write docker tag to",
    required: true,
  });

  return parser.parse_args() as {
    stableStatusFile: string;
    volatileStatusFile: string;
    labelsFile: string;
    tagFile: string;
  };
};

const getStatus = (status: Map<string, string>, name: string) => {
  const v = status.get(name);

  if (v === undefined) {
    throw new Error(
      `couldn't find workspace status ${name}, did you set --workspace_status_command`,
    );
  }

  if (v === "") {
    throw new Error(`workspace status ${name} is empty, this is not allowed`);
  }

  return v;
};

const loadStatus = async (
  stableStatusFile: string,
  volatileStatusFile: string,
) => {
  const stableStatus = parseWorkspaceStatus(
    await readFile(stableStatusFile, "utf8"),
  );
  const volatileStatus = parseWorkspaceStatus(
    await readFile(volatileStatusFile, "utf8"),
  );

  return {
    revision: getStatus(stableStatus, "STABLE_GIT_COMMIT"),
    source: getStatus(stableStatus, "STABLE_GIT_REPO_URL"),
    url: getStatus(stableStatus, "STABLE_WEB_REPO_URL"),
    tag: getStatus(stableStatus, "BUILD_EMBED_LABEL"),
    buildHost: getStatus(stableStatus, "BUILD_HOST"),
    buildUser: getStatus(stableStatus, "BUILD_USER"),
    buildTimestamp: parseInt(getStatus(volatileStatus, "BUILD_TIMESTAMP"), 10),
  };
};

const main = async () => {
  const { stableStatusFile, volatileStatusFile, labelsFile, tagFile } =
    parseArgs();

  const status = await loadStatus(stableStatusFile, volatileStatusFile);

  const labelContent = labelsForStatus(status);
  const { tag } = status;

  await Promise.all([
    writeFile(tagFile, `${tag}\n`),
    writeFile(labelsFile, labelContent),
  ]);
};

await main();
