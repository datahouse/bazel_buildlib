import { readFile } from "node:fs/promises";

describe("extract_from_image", () => {
  it.each(["profile-for-test.txt", "motd-for-test.txt"])(
    "extracts a non-empty file",
    async (fname) => {
      const content = await readFile(
        `private/docker/build/test/${fname}`,
        "utf8",
      );
      expect(content).not.toEqual("");
    },
  );
});
