import type { WorkspaceStatus } from "../../../js-lib/src/loadWorkspaceStatus.js";
import type { BaseProvenanceInfo } from "../src/loadBaseProvenance.js";
import { imageAnnotations } from "../src/imageAnnotations.js";

const fakeStatus: WorkspaceStatus = {
  commit: "da39a3ee5e6b4b0d3255bfef95601890afd80709",
  source: "git@example.com:fake.git",
  url: "https://example.com/git/fake",
  tag: "fake-tag",
  buildHost: "fake-host",
  buildUser: "fake-user",
  buildTime: new Date(1706609068000),
};

const fakeBase: BaseProvenanceInfo = {
  registry: "index.docker.io",
  repository: "library/node",
  digest: "sha256:fake-digest",
};

describe("imageAnnotations", () => {
  it("should create annotations without base", () => {
    const got = imageAnnotations(undefined, fakeStatus);

    const want =
      "org.opencontainers.image.created=2024-01-30T10:04:28.000Z\n" +
      "org.opencontainers.image.authors=\n" +
      "org.opencontainers.image.url=https://example.com/git/fake\n" +
      "org.opencontainers.image.documentation=\n" +
      "org.opencontainers.image.source=git@example.com:fake.git\n" +
      "org.opencontainers.image.version=fake-tag\n" +
      "org.opencontainers.image.revision=da39a3ee5e6b4b0d3255bfef95601890afd80709\n" +
      "org.opencontainers.image.vendor=\n" +
      "org.opencontainers.image.licenses=\n" +
      "org.opencontainers.image.title=\n" +
      "org.opencontainers.image.description=\n" +
      "ch.datahouse.dev.build-host=fake-host\n" +
      "ch.datahouse.dev.build-user=fake-user\n";

    expect(got).toEqual(want);
  });

  it("should not set version for latest", () => {
    const got = imageAnnotations(undefined, { ...fakeStatus, tag: "latest" });

    const want =
      "org.opencontainers.image.created=2024-01-30T10:04:28.000Z\n" +
      "org.opencontainers.image.authors=\n" +
      "org.opencontainers.image.url=https://example.com/git/fake\n" +
      "org.opencontainers.image.documentation=\n" +
      "org.opencontainers.image.source=git@example.com:fake.git\n" +
      "org.opencontainers.image.version=\n" +
      "org.opencontainers.image.revision=da39a3ee5e6b4b0d3255bfef95601890afd80709\n" +
      "org.opencontainers.image.vendor=\n" +
      "org.opencontainers.image.licenses=\n" +
      "org.opencontainers.image.title=\n" +
      "org.opencontainers.image.description=\n" +
      "ch.datahouse.dev.build-host=fake-host\n" +
      "ch.datahouse.dev.build-user=fake-user\n";

    expect(got).toEqual(want);
  });

  it("should add base annotations", () => {
    const got = imageAnnotations(fakeBase, fakeStatus);

    const want =
      "org.opencontainers.image.created=2024-01-30T10:04:28.000Z\n" +
      "org.opencontainers.image.authors=\n" +
      "org.opencontainers.image.url=https://example.com/git/fake\n" +
      "org.opencontainers.image.documentation=\n" +
      "org.opencontainers.image.source=git@example.com:fake.git\n" +
      "org.opencontainers.image.version=fake-tag\n" +
      "org.opencontainers.image.revision=da39a3ee5e6b4b0d3255bfef95601890afd80709\n" +
      "org.opencontainers.image.vendor=\n" +
      "org.opencontainers.image.licenses=\n" +
      "org.opencontainers.image.title=\n" +
      "org.opencontainers.image.description=\n" +
      "ch.datahouse.dev.build-host=fake-host\n" +
      "ch.datahouse.dev.build-user=fake-user\n" +
      "org.opencontainers.image.base.digest=sha256:fake-digest\n" +
      "org.opencontainers.image.base.name=index.docker.io/library/node\n";

    expect(got).toEqual(want);
  });

  it("should reset OCI annotations when unstamped with base", () => {
    const got = imageAnnotations(fakeBase, undefined);

    const want =
      "org.opencontainers.image.created=\n" +
      "org.opencontainers.image.authors=\n" +
      "org.opencontainers.image.url=\n" +
      "org.opencontainers.image.documentation=\n" +
      "org.opencontainers.image.source=\n" +
      "org.opencontainers.image.version=\n" +
      "org.opencontainers.image.revision=\n" +
      "org.opencontainers.image.vendor=\n" +
      "org.opencontainers.image.licenses=\n" +
      "org.opencontainers.image.title=\n" +
      "org.opencontainers.image.description=\n" +
      "org.opencontainers.image.base.digest=sha256:fake-digest\n" +
      "org.opencontainers.image.base.name=index.docker.io/library/node\n";

    expect(got).toEqual(want);
  });

  it("should be empty without base and status", () => {
    expect(imageAnnotations(undefined, undefined)).toEqual("");
  });
});
