import path from "node:path";
import util from "node:util";

import { Readable } from "node:stream";
import { pipeline } from "node:stream/promises";
import streamConsumers from "node:stream/consumers";

import tar from "tar-stream";

import Docker from "dockerode";

import { OCIImage, Descriptor, LayerFormat } from "./OCIImage.js";

interface LoadInput {
  image: OCIImage;
  declaredLayerFiles: string[];
  providedLayers: [string, Descriptor][];
}

/** Streams necessary files for loading into `pack`. */
const streamLoadTar = async (
  { image, declaredLayerFiles, providedLayers }: LoadInput,
  pack: tar.Pack,
): Promise<void> => {
  const pipeBlob = async (name: string, desc: Descriptor) => {
    const { size } = desc;
    const entry = pack.entry({ name, size });
    await pipeline(image.read(desc), entry);
  };

  const manifest = [
    {
      Config: "config.json",
      Layers: declaredLayerFiles,
    },
  ];

  pack.entry({ name: "manifest.json" }, JSON.stringify(manifest));

  await pipeBlob("config.json", image.manifest.config);

  for (const [tarPath, descriptor] of providedLayers) {
    await pipeBlob(tarPath, descriptor);
  }

  pack.finalize();
};

const loadedRE = /^Loaded image ID: sha256:([0-9a-f]{64})\n$/;

type DockerLoadResult = { error: string } | { digest: string };

/** Calls loadImage on the provided Docker and assembles the result. */
const callLoadImage = async (
  input: Readable,
  docker: Docker,
): Promise<DockerLoadResult> => {
  const stream = await docker.loadImage(input);
  const result = await streamConsumers.json(stream);

  // Result *should* have this shape:
  // https://github.com/moby/moby/blob/796da163f92ad486a4f0118b4008d9bd17b27c2e/pkg/jsonmessage/jsonmessage.go#L145-L158
  //
  // The following code is extremely defensive, because it (ab)uses undocumented implementation details.

  const badResult = () => {
    const str = util.inspect(result);
    throw new Error(
      `unexpected result from Docker daemon (report this as a dh_buildlib bug): ${str}`,
    );
  };

  const asString = (x: unknown): string =>
    typeof x !== "string" ? badResult() : x;

  if (typeof result !== "object" || result === null) {
    return badResult();
  }

  if ("error" in result) {
    return { error: asString(result.error) };
  }

  if (!("stream" in result)) {
    return badResult();
  }

  const streamMatch = asString(result.stream).match(loadedRE);

  if (!streamMatch) return badResult();

  return { digest: streamMatch[1] };
};

const dockerLoadImage = async (
  input: LoadInput,
  docker: Docker,
): Promise<DockerLoadResult> => {
  const pack = tar.pack();

  const tarPromise = streamLoadTar(input, pack);
  const dockerPromise = callLoadImage(pack, docker);

  const [loadResult] = await Promise.all([dockerPromise, tarPromise]);

  if ("error" in loadResult) return loadResult;

  // Check the digest matches the OCIImage manifest.
  const ociDigest = `sha256:${loadResult.digest}`;
  const dockerDigest = input.image.manifest.config.digest;

  if (ociDigest !== dockerDigest) {
    throw new Error(
      "after loading, Docker reported a different image digest than the original image. " +
        `OCIImage: ${ociDigest} Docker: ${dockerDigest}. Please report this as a dh_buildlib bug.`,
    );
  }

  return loadResult;
};

const fakeLayerRE = /fake-layer-for-inc-load-(\d+)\.tar/;

/** Tries to load the image without providing any layer data for speed.
 *  - If it succeeds, we're done.
 *  - If it fails, we can figure out which layers are missing and only send these (for speed).
 */
const opportunisticLoad = async (
  image: OCIImage,
  docker: Docker,
): Promise<{ digest: string } | { firstLayerIdxToLoad: number }> => {
  const fakeLayerFiles = Array.from(
    image.manifest.layers.keys(),
    (i) => `fake-layer-for-inc-load-${i}.tar`,
  );

  const loadResult = await dockerLoadImage(
    {
      image,
      declaredLayerFiles: fakeLayerFiles,
      providedLayers: [],
    },
    docker,
  );

  if ("digest" in loadResult) {
    // Loading succeeded: We already had all the layers.
    return { digest: loadResult.digest };
  }

  const reMatch = loadResult.error.match(fakeLayerRE);

  if (!reMatch) {
    throw new Error(
      `got unexpected error from docker daemon: ${loadResult.error}`,
    );
  }

  // Get the index from the match.
  return { firstLayerIdxToLoad: parseInt(reMatch[1], 10) };
};

const layerExts: Record<LayerFormat, string> = {
  tar: ".tar",
  "tar+gzip": ".tar.gz",
};

const fullLoad = async (
  image: OCIImage,
  firstLayerIdxToLoad: number,
  docker: Docker,
): Promise<string> => {
  const {
    manifest: { layers },
  } = image;

  const layerPath = (l: Descriptor) =>
    path.format({
      name: l.digest,
      ext: layerExts[OCIImage.layerFormat(l)],
    });

  const loadResult = await dockerLoadImage(
    {
      image,
      // all layers, not just the ones to load.
      declaredLayerFiles: layers.map(layerPath),
      // only the ones to load.
      providedLayers: layers
        .slice(firstLayerIdxToLoad)
        .map((l) => [layerPath(l), l]),
    },
    docker,
  );

  if ("digest" in loadResult) return loadResult.digest;

  throw new Error(`loading to docker failed: ${loadResult.error}`);
};

const loadImageToDocker = async (image: OCIImage): Promise<string> => {
  const docker = new Docker();

  const fastLoadResult = await opportunisticLoad(image, docker);

  if ("digest" in fastLoadResult) return fastLoadResult.digest;

  const { firstLayerIdxToLoad } = fastLoadResult;

  return fullLoad(image, firstLayerIdxToLoad, docker);
};

export default loadImageToDocker;

export const loadImageDirToDocker = async (dir: string): Promise<string> =>
  loadImageToDocker(await OCIImage.load(dir));
