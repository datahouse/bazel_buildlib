import { env } from "node:process";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";

import type { Readable } from "node:stream";

import { createInterface as createReadlineInterface } from "node:readline";

import { spawn } from "node:child_process";
import { mkdir, mkdtempDisposable, symlink, writeFile } from "node:fs/promises";

import { z } from "zod";

import { OCIImage } from "../../lib/src/OCIImage.js";

import { pickStrategy } from "./serveStrategy.js";
import { zotBinPath } from "./bazelVars.js";

const zotLogSchema = z.object({
  message: z.string(),
  error: z.string().optional(),
  port: z.number().optional(),
});

interface ReadyResult {
  portInUse: boolean;
  port?: number;
  log: string[];
}

const moveDisposer = <T>(
  value: T,
  disposer: AsyncDisposableStack,
): T & AsyncDisposable => {
  const capture = disposer.move();
  return {
    ...value,
    [Symbol.asyncDispose]: () => capture.disposeAsync(),
  };
};

// Note: does not throw itself so linter can see `throw` for flow analysis.
const mkError = (msg: string, log: string[]): Error =>
  new Error(`${msg}:\n${log.join("\n")}`);

const waitForReady = async (input: Readable): Promise<ReadyResult> => {
  const rl = createReadlineInterface({ input, crlfDelay: Infinity });
  const log: string[] = [];
  let reportedPort: number | undefined;

  for await (const line of rl) {
    log.push(line); // startup log is only a dozen lines or so, keep all of it.

    const { port, message, error } = zotLogSchema.parse(JSON.parse(line));

    if (port) reportedPort = port;

    if (message === "ready") {
      // https://github.com/project-zot/zot/blob/80cad7188de5d8f8389e1618dd69d2f13e1d3f54/pkg/common/healthz.go#L56-L59
      // Debug level only unfortunately, but better than an additional prober.
      // serveImages.test.ts tests for this.
      return { portInUse: false, port: reportedPort, log };
    }

    if (error?.includes("bind: address already in use")) {
      // golang error message: brittle but the best we can do.
      // serveImages.test.ts tests for this.
      return { portInUse: true, log };
    }
  }

  throw mkError("zot terminated unexpectedly", log);
};

const linkImages = async (storageDir: string, images: Map<string, string>) => {
  await mkdir(storageDir, { recursive: true });
  for (const [repoName, dir] of images) {
    // resolve to be cwd agnostic.
    await symlink(resolve(dir), join(storageDir, repoName));
  }
};

const writeConfig = async (
  rootDirectory: string,
  address: string,
  port: number,
  configPath: string,
) => {
  const config = {
    http: { address, port },
    // `log: { level: "debug" }` is the default
    // (which we rely on for the ready message).
    storage: {
      rootDirectory,
      // turn off subsystems that attempt to write.
      gc: false,
      dedupe: false,
    },
  };

  await writeFile(configPath, JSON.stringify(config));
};

const start = async (
  images: Map<string, string>,
  address: string,
  port: number, // may be 0 to mean any port
): Promise<ReadyResult & AsyncDisposable> => {
  await using disposer = new AsyncDisposableStack();

  const workDir = disposer.use(
    await mkdtempDisposable(join(tmpdir(), "dh-buildlib-zot-")),
  );

  const storageDir = join(workDir.path, "storage");
  const configPath = join(workDir.path, "config.json");

  await linkImages(storageDir, images);
  await writeConfig(storageDir, address, port, configPath);

  const child = disposer.use(
    spawn(join(env.RUNFILES_DIR!, zotBinPath), ["serve", configPath], {
      // zot *should* not write to stderr.
      // set to ignore to prevent unbounded buffering.
      stdio: ["ignore", "pipe", "ignore"],
    }),
  );

  const readyResult = await waitForReady(child.stdout);
  child.stdout.resume(); // drain

  return moveDisposer(readyResult, disposer);
};

export interface EphemeralRegistry extends AsyncDisposable {
  address: string;
  port: number;
}

export const serveImages = async (
  images: Map<string, string>,
): Promise<EphemeralRegistry> => {
  await using disposer = new AsyncDisposableStack();

  const { bindAddress, pullAddress } = await pickStrategy();

  const result = disposer.use(await start(images, bindAddress, 0));

  if (result.portInUse)
    throw mkError("zot reported port in use with port 0", result.log);

  const { port } = result;

  if (!port) throw mkError("zot did not report a port", result.log);

  return moveDisposer({ address: `${pullAddress}:${port}`, port }, disposer);
};

// Returns undefined if port is in use.
export const serveImagesWithPort = async (
  images: Map<string, string>,
  port: number,
): Promise<EphemeralRegistry | undefined> => {
  if (port === 0) return serveImages(images);

  await using disposer = new AsyncDisposableStack();

  const { bindAddress, pullAddress } = await pickStrategy();

  const result = disposer.use(await start(images, bindAddress, port));

  if (result.portInUse) return undefined;

  // We could check `result.port`, but it does not really matter.
  // Note that zot does not (re-)report an explicitly specified port:
  // https://github.com/project-zot/zot/blob/80cad7188de5d8f8389e1618dd69d2f13e1d3f54/pkg/api/listener.go#L138-L142

  return moveDisposer({ address: `${pullAddress}:${port}`, port }, disposer);
};

export interface ServedImage extends AsyncDisposable {
  ref: string;
}

// Convenience method to serve a single image
export const serveImage = async (imageDir: string): Promise<ServedImage> => {
  const {
    manifestDescriptor: { digest },
  } = await OCIImage.load(imageDir);

  const registry = await serveImages(new Map([["image", imageDir]]));

  return {
    ref: `${registry.address}/image@${digest}`,
    [Symbol.asyncDispose]: () => registry[Symbol.asyncDispose](),
  };
};
