import { readFile, writeFile } from "node:fs/promises";

import argparse from "argparse";

import parseWorkspaceStatus from "../../js-lib/src/parseWorkspaceStatus.js";

const parseArgs = () => {
  const parser = new argparse.ArgumentParser({
    description: "Bazel workspace status loader",
  });

  parser.add_argument("--infoFile", {
    help: "workspace status info file (ctx.info_file)",
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
    infoFile: string;
    labelsFile: string;
    tagFile: string;
  };
};

const getStatuses = (status: Map<string, string>) => {
  const get = (name: string) => {
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

  return {
    revision: get("STABLE_GIT_COMMIT"),
    source: get("STABLE_GIT_REPO_URL"),
    url: get("STABLE_WEB_REPO_URL"),
    tag: get("BUILD_EMBED_LABEL"),
  };
};

const main = async () => {
  const { infoFile, labelsFile, tagFile } = parseArgs();

  const status = parseWorkspaceStatus(await readFile(infoFile, "utf8"));

  const { revision, source, url, tag } = getStatuses(status);

  const labelContent =
    `org.opencontainers.image.revision=${revision}\n` +
    `org.opencontainers.image.source=${source}\n` +
    `org.opencontainers.image.url=${url}\n`;

  await Promise.all([
    writeFile(tagFile, `${tag}\n`),
    writeFile(labelsFile, labelContent),
  ]);
};

main().catch((err) => {
  console.log(err);
  process.exit(1);
});
