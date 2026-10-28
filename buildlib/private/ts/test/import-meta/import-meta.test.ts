// Regression test for the babel-jest import.meta pipeline (see babel.config.cts).
declare global {
  interface ImportMeta {
    url: string;
  }
}

test("import.meta works under the babel-jest CommonJS pipeline", () => {
  // Keep `import.meta.url` a direct member access; hoisting it to a variable
  // would let the residual plugin rewrite the bare meta to `{}` first.
  expect(typeof import.meta.url).toBe("string");

  // Bare `import.meta` and unknown props (e.g. `import.meta.hot`) -> `{}`.
  expect(import.meta).toEqual({});
});
