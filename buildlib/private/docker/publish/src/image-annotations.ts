import { readFile, writeFile } from "node:fs/promises";

import argparse from "argparse";

import { loadWorkspaceStatus } from "../../../js-lib/src/loadWorkspaceStatus.js";
import { OCIImage } from "../../lib/src/OCIImage.js";
import { loadBaseProvenance } from "./loadBaseProvenance.js";
import { imageAnnotations } from "./imageAnnotations.js";

const parseArgs = () => {
  const parser = new argparse.ArgumentParser({
    description: "OCI image annotations generator",
  });

  parser.add_argument("--baseMetadataFile", {
    help: "base image metadata file",
  });
  parser.add_argument("--baseImage", {
    help: "base image directory",
  });
  parser.add_argument("--stableStatusFile", {
    help: "stable workspace status file",
  });
  parser.add_argument("--volatileStatusFile", {
    help: "volatile workspace status file",
  });
  parser.add_argument("--output", {
    help: "file to write annotations to",
    required: true,
  });

  return parser.parse_args<{
    baseMetadataFile?: string;
    baseImage?: string;
    stableStatusFile?: string;
    volatileStatusFile?: string;
    output: string;
  }>();
};

const main = async () => {
  const {
    baseMetadataFile,
    baseImage,
    stableStatusFile,
    volatileStatusFile,
    output,
  } = parseArgs();

  const baseInfo =
    baseMetadataFile && baseImage
      ? loadBaseProvenance(
          await readFile(baseMetadataFile, "utf8"),
          await OCIImage.load(baseImage),
        )
      : undefined;

  const workspaceStatus =
    stableStatusFile && volatileStatusFile
      ? await loadWorkspaceStatus(stableStatusFile, volatileStatusFile)
      : undefined;

  const content = imageAnnotations(baseInfo, workspaceStatus);

  await writeFile(output, content);
};

await main();
