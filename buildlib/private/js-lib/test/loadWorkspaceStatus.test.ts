import { writeFile } from "node:fs/promises";
import { env } from "node:process";
import { join } from "node:path";

import { loadWorkspaceStatus } from "../src/loadWorkspaceStatus.js";

const fakeStableStatus = `
STABLE_GIT_COMMIT 0123456789abcdef
STABLE_GIT_REPO_URL https://git.example.com/repo.git
STABLE_WEB_REPO_URL https://web.example.com/repo
BUILD_EMBED_LABEL v1.2.3
BUILD_HOST build host
BUILD_USER build user
UNUSED_KEY unused value
`;

const fakeVolatileStatus = `
BUILD_TIMESTAMP 1700000000
`;

describe("loadWorkspaceStatus", () => {
  const run = async (stableStatus: string, volatileStatus: string) => {
    const testName = expect.getState().currentTestName;
    const stableFile = join(env.TEST_TMPDIR!, `${testName}-stable.txt`);
    const volatileFile = join(env.TEST_TMPDIR!, `${testName}-volatile.txt`);

    await writeFile(stableFile, stableStatus);
    await writeFile(volatileFile, volatileStatus);

    return loadWorkspaceStatus(stableFile, volatileFile);
  };

  it("loads workspace status", async () => {
    await expect(run(fakeStableStatus, fakeVolatileStatus)).resolves.toEqual({
      commit: "0123456789abcdef",
      source: "https://git.example.com/repo.git",
      url: "https://web.example.com/repo",
      tag: "v1.2.3",
      buildHost: "build host",
      buildUser: "build user",
      buildTime: new Date("2023-11-14T22:13:20Z"),
    });
  });

  it("rejects on missing key", async () => {
    await expect(run(fakeStableStatus, "")).rejects.toThrow(
      /couldn't find workspace status BUILD_TIMESTAMP/,
    );
  });

  it("rejects on empty value", async () => {
    const emptyTimeVolatileStatus = "BUILD_TIMESTAMP\n";

    await expect(
      run(fakeStableStatus, emptyTimeVolatileStatus),
    ).rejects.toThrow(
      /workspace status BUILD_TIMESTAMP is empty, this is not allowed/,
    );
  });

  it.each(["abc", "123abc", "1.5"])(
    "rejects on invalid timestamp '%s'",
    async (timestamp) => {
      await expect(
        run(fakeStableStatus, `BUILD_TIMESTAMP ${timestamp}\n`),
      ).rejects.toThrow(
        `workspace status BUILD_TIMESTAMP is not a timestamp: '${timestamp}'`,
      );
    },
  );
});
