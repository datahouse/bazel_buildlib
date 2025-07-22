test("failure source mapping", () => {
  // Just use some typescript syntax.
  // This allows us to check that jest can resolve the source maps and give
  // error context on the original typescript file.
  expect(1 as const).toEqual(0);
});
