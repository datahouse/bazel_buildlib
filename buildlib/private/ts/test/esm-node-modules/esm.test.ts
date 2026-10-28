import { generateSecret } from "jose"; // known esm only package.

test("esm node modules", async () => {
  // Just check we can call the imported function.
  await expect(generateSecret("HS256")).resolves.not.toBeUndefined();
});
