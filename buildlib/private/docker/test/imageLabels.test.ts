import { labelsForStatus, Status } from "../src/imageLabels.js";

const fakeStatus: Status = {
  revision: "da39a3ee5e6b4b0d3255bfef95601890afd80709",
  source: "git@example.com:fake.git",
  url: "https://example.com/git/fake",
  tag: "fake-tag",
  buildHost: "fake-host",
  buildUser: "fake-user",
  buildTimestamp: 1706609068,
};

describe("labelsForStatus", () => {
  it("should create labels", () => {
    const got = labelsForStatus(fakeStatus);

    const want =
      "org.opencontainers.image.revision=da39a3ee5e6b4b0d3255bfef95601890afd80709\n" +
      "org.opencontainers.image.source=git@example.com:fake.git\n" +
      "org.opencontainers.image.url=https://example.com/git/fake\n" +
      "org.opencontainers.image.created=2024-01-30T10:04:28.000Z\n" +
      "ch.datahouse.dev.build-host=fake-host\n" +
      "ch.datahouse.dev.build-user=fake-user\n" +
      "org.opencontainers.image.version=fake-tag\n";

    expect(got).toEqual(want);
  });

  it("should not set version for latest", () => {
    const got = labelsForStatus({ ...fakeStatus, tag: "latest" });

    const want =
      "org.opencontainers.image.revision=da39a3ee5e6b4b0d3255bfef95601890afd80709\n" +
      "org.opencontainers.image.source=git@example.com:fake.git\n" +
      "org.opencontainers.image.url=https://example.com/git/fake\n" +
      "org.opencontainers.image.created=2024-01-30T10:04:28.000Z\n" +
      "ch.datahouse.dev.build-host=fake-host\n" +
      "ch.datahouse.dev.build-user=fake-user\n";

    expect(got).toEqual(want);
  });

  it("should throw if buildTimestamp is not a number", () => {
    expect(() =>
      labelsForStatus({ ...fakeStatus, buildTimestamp: NaN }),
    ).toThrow();
  });
});
