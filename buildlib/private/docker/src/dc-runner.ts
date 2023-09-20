import process from "node:process";
import { homedir } from "node:os";
import path from "node:path";
import { spawn as spawnRaw } from "node:child_process";

import { ImageInfo, readImageInfos } from "./ImageInfos";
import syncFiles from "./syncFiles";

// Promisified variant of spawn that always inherits IO.
const spawn = async (command: string, ...args: string[]): Promise<void> =>
  new Promise((res, rej) => {
    const childProcess = spawnRaw(command, args, { stdio: "inherit" });

    childProcess.on("error", rej);
    childProcess.on("close", (code) => {
      if (code !== 0) rej(new Error(`${command} exited with code ${code}`));
      else res();
    });
  });

const loadImage = async (info: ImageInfo) => {
  if ("loadCmd" in info) await spawn(info.loadCmd, "--norun");
};

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
  const [
    ,
    ,
    dockerPath,
    pinnedDcPath,
    composeProject,
    imageInfoPath,
    ...composeArgs
  ] = process.argv;

  const imageInfos = await readImageInfos(imageInfoPath);

  await Promise.all(
    Object.values(imageInfos).flatMap((info) => [
      loadImage(info),
      syncHot(info),
    ]),
  );

  await spawn(
    dockerPath,
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
