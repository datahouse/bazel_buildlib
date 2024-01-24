import { readFile } from "node:fs/promises";
import { myLibraryFunction, appInfo } from "../src/index.js";

describe("shared-lib", () => {
  it("should sum the arguments", () =>
    expect(myLibraryFunction(1, 2)).toEqual(3));

  it("produce an app info string", () => {
    expect(appInfo()).toMatch(/^it-bazel example .+$/);
  });

  it("should have access to test data", async () => {
    const content = await readFile("shared-lib/test/data-file.txt", "utf8");
    expect(content).toEqual("the-data\n");
  });
});
