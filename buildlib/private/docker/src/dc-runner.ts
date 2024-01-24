import process from "node:process";
import { homedir } from "node:os";
import path from "node:path";

import spawnInheritIO from "./spawnInheritIO.js";
import { ImageInfo, readImageInfos } from "./ImageInfos.js";
import syncFiles from "./syncFiles.js";
import { loadImageDirToDocker } from "./loadImageToDocker.js";

const syncHot = async (info: ImageInfo) => {
  if (!("hotReload" in info) || !info.hotReload) return;

  const { files, hostHomePath } = info.hotReload;

  const hostPath = path.join(homedir(), hostHomePath);

  await syncFiles(process.cwd(), hostPath, files);
};

const main = async () => {
  // Ignore first 2 args:
  // - The name of the node binary
  // - The path to the JS script.
  const [, , pinnedDcPath, composeProject, imageInfoPath, ...composeArgs] =
    process.argv;

  const imageInfos = await readImageInfos(imageInfoPath);

  await Promise.all(
    Object.values(imageInfos).flatMap((info) => [
      loadImageDirToDocker(info.ociDirShort),
      syncHot(info),
    ]),
  );

  await spawnInheritIO(
    "docker",
    "compose",
    "--project-name",
    composeProject,
    "--file",
    pinnedDcPath,
    ...composeArgs,
  );
};

main().catch((err) => {
  console.log(err);
  process.exit(1);
});
