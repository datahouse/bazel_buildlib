import { z } from "zod";

import type { OCIImage } from "../../lib/src/OCIImage.js";

export interface BaseProvenanceInfo {
  registry: string;
  repository: string;
  digest: string;
  // Ideally we'd get a tag as well. However, the docker purl we use from
  // rules_oci upstream does not contain it (docker purl's can't contain both a tag and a digest).
  // Note that an oci purl could contain an (additional) tag. We'd have to upstream this change.
}

const packageMetadataSchema = z.object({
  purl: z.string(),
});

export const loadBaseProvenance = (
  basePackageMetadata: string,
  { manifestDescriptor: { digest } }: OCIImage,
): BaseProvenanceInfo => {
  const rawMetadata = JSON.parse(basePackageMetadata) as unknown;
  const { purl: rawPurl } = packageMetadataSchema.parse(rawMetadata);
  const purl = new URL(rawPurl);

  // purl should look like this:
  // where <identifier> is a digest or tag (which we ignore)
  // pkg:docker/library/node@<identifier>?repository_url=index.docker.io

  if (purl.protocol !== "pkg:")
    throw new Error(`unexpected scheme: ${rawPurl}`);

  const pathMatch = purl.pathname.match(/^docker\/([^@]+)@/);

  if (pathMatch === null) throw new Error(`not a docker purl: ${rawPurl}`);

  const repository = pathMatch[1];

  const registry = purl.searchParams.get("repository_url");

  if (registry === null) throw new Error(`no repository_url: ${rawPurl}`);

  return { registry, repository, digest };
};
