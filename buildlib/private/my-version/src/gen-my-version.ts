import fs from "fs/promises";
import argparse from "argparse";

import parseWorkspaceStatus from "../../js-lib/src/parseWorkspaceStatus.js";

// Stamp and workspace status aware calculation of my version.
async function calcMyVersion(infoFile: string): Promise<string> {
  const status = parseWorkspaceStatus(await fs.readFile(infoFile, "utf8"));

  const commit = status.get("STABLE_GIT_COMMIT");

  if (commit === undefined) {
    throw new Error(`expected STABLE_GIT_COMMIT in workspace status`);
  }

  const label = status.get("BUILD_EMBED_LABEL") || "";

  return `${label}+${commit}`;
}

const main = async () => {
  const parser = new argparse.ArgumentParser({
    description: "Bazel workspace status loader",
  });

  parser.add_argument("--info-file", {
    help: "workspace status info file (ctx.info_file)",
  });

  parser.add_argument("output", {
    help: "output filename",
  });

  const args = parser.parse_args();

  const myVersion = await calcMyVersion(args.info_file);

  await fs.writeFile(args.output, myVersion, "utf8");
};

main().catch((err) => {
  console.log(err);
  process.exit(1);
});
