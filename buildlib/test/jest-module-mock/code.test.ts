import moduleToMock from "./moduleToMock";
import codeUnderTest from "./code";

// README: This test checks whether jest module mocking works (see #247).
//
// In general: DO NOT use jest.mock. It makes it intractable which parts of the
// code under tests are replaced with a test double.
//
// Instead, use explicit dependency injection.
// See code.better.test.ts for an example.

// eslint-disable-next-line no-restricted-syntax
jest.mock("./moduleToMock");

const mockedModule = jest.mocked(moduleToMock);

it("should mock", () => {
  mockedModule.mockReturnValue("mocked return value");

  expect(codeUnderTest("argument from test")).toEqual("mocked return value");

  expect(mockedModule).toHaveBeenCalledWith("argument from test");
});
