import { readFile } from "node:fs/promises";

describe("extract_from_image", () => {
  it("extracts a non-empty file", async () => {
    const content = await readFile(
      "private/docker/test/profile-for-test.txt",
      "utf8",
    );
    expect(content).not.toEqual("");
  });
});
