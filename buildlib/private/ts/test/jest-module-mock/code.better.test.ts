import { codeUnderTestInternal } from "./code.better.js";

// This is an  example of how to stub / mock / fake out dependencies in tests
// without using jest.mock.

it("should work", () => {
  const dep = jest.fn();

  dep.mockReturnValue("mocked return value");

  expect(codeUnderTestInternal("argument from test", dep)).toEqual(
    "mocked return value",
  );

  expect(dep).toHaveBeenCalledWith("argument from test");
});
