import { readFile } from "node:fs/promises";
import { myLibraryFunction, greeting } from "../src";

describe("shared-lib", () => {
  it("should sum the arguments", () =>
    expect(myLibraryFunction(1, 2)).toEqual(3));

  it("produce a greeting", () => {
    expect(greeting()).toMatch(/^Hello from .+$/);
  });

  it("should have access to test data", async () => {
    const content = await readFile("shared-lib/test/data-file.txt", "utf8");
    expect(content).toEqual("the-data\n");
  });
});
