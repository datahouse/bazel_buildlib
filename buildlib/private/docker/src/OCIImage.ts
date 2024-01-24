import path from "node:path";

import { Readable } from "node:stream";

import { createReadStream } from "node:fs";
import { readFile } from "node:fs/promises";

export type LayerFormat = "tar" | "tar+gzip";

export interface Descriptor {
  mediaType: string;
  digest: string;
  size: number;
}

export interface ImageManifest {
  schemaVersion: number;
  config: Descriptor;
  layers: Descriptor[];
}

interface OCILayout {
  imageLayoutVersion: string;
}

interface ImageIndex {
  schemaVersion: number;
  mediaType?: string;
  manifests: Descriptor[];
}

const readJSON = async <T>(p: string): Promise<T> =>
  JSON.parse(await readFile(p, "utf8")) as T;

const checkLayoutVersion = async (dir: string) => {
  const { imageLayoutVersion } = await readJSON<OCILayout>(
    path.join(dir, "oci-layout"),
  );

  if (imageLayoutVersion !== "1.0.0") {
    // Note: Once this breaks because of a semver compatible version (say 1.1.0),
    // we should adjust the check above.
    throw new Error(
      `only OCI layout 1.0.0 is supported, found ${imageLayoutVersion}`,
    );
  }
};

const checkOneManifest = (manifests: Descriptor[]) => {
  if (manifests.length !== 1)
    throw new Error(`expected 1 manfest, got ${manifests}`);

  return manifests[0];
};

const blobPath = (base: string, { digest }: Descriptor): string => {
  const idx = digest.indexOf(":");
  if (idx === -1) {
    throw new Error(`Expected '${digest}' to contain ':'`);
  }

  const alg = digest.slice(0, idx);
  const encoded = digest.slice(idx + 1);

  return path.join(base, "blobs", alg, encoded);
};

const loadManifest = (
  base: string,
  desc: Descriptor,
): Promise<ImageManifest> => {
  const { mediaType } = desc;
  const manifestPath = blobPath(base, desc);

  switch (mediaType) {
    case "application/vnd.oci.image.manifest.v1+json":
      return readJSON<ImageManifest>(manifestPath);

    case "application/vnd.docker.distribution.manifest.v2+json":
      return readJSON<ImageManifest>(manifestPath);

    default:
      throw new Error(`unsupported manifest mediaType: ${mediaType}`);
  }
};

/** Class to interface with a single image OCI layout. */
export class OCIImage {
  static async load(dir: string): Promise<OCIImage> {
    await checkLayoutVersion(dir);
    const { manifests } = await readJSON<ImageIndex>(
      path.join(dir, "index.json"),
    );

    const manifest = await loadManifest(dir, checkOneManifest(manifests));

    return new OCIImage(dir, manifest);
  }

  private constructor(
    private dir: string,
    public readonly manifest: ImageManifest,
  ) {}

  read(desc: Descriptor): Readable {
    return createReadStream(blobPath(this.dir, desc));
  }

  static layerFormat({ mediaType }: Descriptor): LayerFormat {
    switch (mediaType) {
      case "application/vnd.oci.image.layer.v1.tar":
      case "application/vnd.oci.image.layer.nondistributable.v1.tar":
        return "tar";

      case "application/vnd.docker.image.rootfs.diff.tar.gzip":
      case "application/vnd.oci.image.layer.v1.tar+gzip":
      case "application/vnd.oci.image.layer.nondistributable.v1.tar+gzip":
        return "tar+gzip";

      default:
        throw new Error(`unsupported layer mediaType: ${mediaType}`);
    }
  }
}
