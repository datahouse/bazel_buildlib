import path from "node:path";

import { readFile } from "node:fs/promises";

import { z } from "zod";

const descriptorSchema = z.object({
  mediaType: z.string(),
  digest: z.string(),
  size: z.number(),
});

export type Descriptor = z.infer<typeof descriptorSchema>;

const imageManifestSchema = z.object({
  schemaVersion: z.number(),
  config: descriptorSchema,
  layers: z.array(descriptorSchema),
});

export type ImageManifest = z.infer<typeof imageManifestSchema>;

const ociLayoutSchema = z.object({
  imageLayoutVersion: z.string(),
});

const imageIndexSchema = z.object({
  schemaVersion: z.number(),
  mediaType: z.string().optional(),
  manifests: z.array(descriptorSchema),
});

const readJSON = async <T>(schema: z.ZodType<T>, p: string): Promise<T> =>
  schema.parse(JSON.parse(await readFile(p, "utf8")));

const checkLayoutVersion = async (dir: string) => {
  const { imageLayoutVersion } = await readJSON(
    ociLayoutSchema,
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
    throw new Error(`expected 1 manfest, got ${manifests.length}`);

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
      return readJSON(imageManifestSchema, manifestPath);

    case "application/vnd.docker.distribution.manifest.v2+json":
      return readJSON(imageManifestSchema, manifestPath);

    default:
      throw new Error(`unsupported manifest mediaType: ${mediaType}`);
  }
};

/** Class to interface with a single image OCI layout. */
export class OCIImage {
  static async load(dir: string): Promise<OCIImage> {
    await checkLayoutVersion(dir);
    const { manifests } = await readJSON(
      imageIndexSchema,
      path.join(dir, "index.json"),
    );

    const manifestDescriptor = checkOneManifest(manifests);
    const manifest = await loadManifest(dir, manifestDescriptor);

    return new OCIImage(dir, manifest, manifestDescriptor);
  }

  private constructor(
    private dir: string,
    public readonly manifest: ImageManifest,
    public readonly manifestDescriptor: Descriptor,
  ) {}

  blobPath(desc: Descriptor): string {
    return blobPath(this.dir, desc);
  }
}
