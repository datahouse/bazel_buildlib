import type { OCIImage } from "../../lib/src/OCIImage.js";

import { loadBaseProvenance } from "../src/loadBaseProvenance.js";

const fakeDigest = "fake-digest";

const fakeImage = {
  manifestDescriptor: {
    digest: fakeDigest,
  },
} as OCIImage;

describe("loadBaseProvenance", () => {
  const withPurl = (purl: string) =>
    loadBaseProvenance(JSON.stringify({ purl }), fakeImage);

  it("should load info", () => {
    const got = withPurl(
      "pkg:docker/library/node@my-tag?repository_url=index.docker.io",
    );

    expect(got).toEqual({
      registry: "index.docker.io",
      repository: "library/node",
      digest: fakeDigest,
    });
  });

  it.each([
    [
      "non-pkg scheme",
      "https://example.com",
      "unexpected scheme: https://example.com",
    ],
    [
      "non-docker purl",
      "pkg:npm/left-pad@1.3.0?repository_url=registry.npmjs.org",
      "not a docker purl",
    ],
    [
      "missing repository_url",
      "pkg:docker/library/node@my-tag",
      "no repository_url",
    ],
  ])("should reject %s", (_, purl, errMsg) => {
    expect(() => withPurl(purl)).toThrow(errMsg);
  });
});
