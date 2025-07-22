import { execFileWithCode } from "../src/execFileWithCode.js";

describe("execFileWithCode", () => {
  it("resolves with zero exit code", async () => {
    const { code } = await execFileWithCode("true");
    expect(code).toEqual(0);
  });

  it("resolves with non-zero exit code", async () => {
    const { code } = await execFileWithCode("false");
    expect(code).not.toEqual(0);
  });

  it("rejects throws  returns non-zero code", async () => {
    const promise = execFileWithCode("nonexistent-binary");
    await expect(promise).rejects.toThrow(/ENOENT/);
  });
});
