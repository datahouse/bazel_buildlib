import process from "node:process";
import { homedir } from "node:os";
import { dirname } from "node:path";
import { readFile as readFileCallback } from "node:fs";
import { writeFile, unlink, mkdir } from "node:fs/promises";

import { spawnInheritIO } from "../../../js-lib/src/spawnInheritIO.js";

import { serveImagesWithPort } from "../../load/src/serveImages.js";

import { hotCachePath, portFilePath } from "./cachePaths.js";
import { ImageInfo, readImageInfos } from "./ImageInfos.js";
import syncFiles from "./syncFiles.js";

const syncHot = async (composeProject: string, info: ImageInfo) => {
  if (!("hotReload" in info) || !info.hotReload) return;

  const { files, hostSubPath } = info.hotReload;

  const hostPath = hotCachePath(homedir(), composeProject, hostSubPath);

  await syncFiles(process.cwd(), hostPath, files);
};

const readFileIfExists = (path: string): Promise<string | undefined> =>
  new Promise((res, rej) => {
    // callback-based to have error type
    readFileCallback(path, "utf8", (err, content) => {
      if (err && err.code === "ENOENT") res(undefined);
      else if (err) rej(err);
      else res(content);
    });
  });

const readPort = async (portFile: string): Promise<number> => {
  const content = await readFileIfExists(portFile);

  if (content === undefined) return 0; // bind to any available port

  const port = Number(content);
  if (Number.isInteger(port) && port >= 1024 && port <= 65535) return port;

  throw new Error(`invalid port ${content} in port file ${portFile}`);
};

const writePort = async (portFile: string, port: number): Promise<void> => {
  await mkdir(dirname(portFile), { recursive: true });
  await writeFile(portFile, String(port));
};

const cannotBindPortErrorMsg = (port: number) => `
Unable to bind to previous compose image serving port (${port})

buildlib runs an internal OCI (Docker) registry to make images available to Compose.

In order to avoid that Compose recreates containers unnecessarily (because the port in the \`image\` changed)
it will attempt to bind to the same port on the next invocation. You see this message because this failed.

Re-run the command to pick a different port. This will recreate your containers.
There is nothing really else you can do, but please let us know if this happens too often.
`;

const main = async () => {
  // Ignore first 2 args:
  // - The name of the node binary
  // - The path to the JS script.
  const [
    ,
    ,
    composeExecutable,
    pinnedDcPath,
    composeProject,
    imageInfoPath,
    ...composeArgs
  ] = process.argv;

  const imageInfos = await readImageInfos(imageInfoPath);
  const images = new Map(
    imageInfos.map((info) => [info.zotRepoName, info.ociDirShort]),
  );

  const portFile = portFilePath(homedir(), composeProject);

  const port = await readPort(portFile);

  await using registry = await serveImagesWithPort(images, port);

  // Note: we may *not* call exit, to make sure `using` cleanup handlers run.

  if (registry === undefined) {
    process.stderr.write(cannotBindPortErrorMsg(port));
    await unlink(portFile);
    process.exitCode = 1;
  } else {
    await Promise.all([
      writePort(portFile, registry.port),
      ...imageInfos.map((info) => syncHot(composeProject, info)),
    ]);

    // Forward exit code. If there is a problem, compose itself will have reported it.
    process.exitCode = await spawnInheritIO(
      composeExecutable,
      [
        "--project-name",
        composeProject,
        "--file",
        pinnedDcPath,
        ...composeArgs,
      ],
      {
        env: {
          ...process.env,
          // BAZEL_IMAGE mirrors the `bazel-image` key: it holds the registry address
          // (host:port) serving bazel built images, not an image itself.
          BAZEL_IMAGE: registry.address,
        },
      },
    );
  }
};

await main();
