import Docker from "dockerode";

import { serveImage } from "./serveImages.js";

const pullImage = async (ref: string): Promise<void> => {
  const docker = new Docker();
  const stream = await docker.pull(ref);

  return new Promise((res, rej) => {
    docker.modem.followProgress(stream, (err) => (err ? rej(err) : res()));
  });
};

export const loadImageDirToDocker = async (dir: string): Promise<string> => {
  await using image = await serveImage(dir);

  const { ref } = image;

  await pullImage(ref);

  // image @ ref is loaded, so we can use the ref, even if the registry
  // is not running anymore.
  return ref;
};
