import fun from "./moduleToMock";

// exported for tests
export const codeUnderTestInternal = (
  arg: string,
  dep: (arg: string) => string,
) => dep(arg);

const codeUnderTest = (arg: string) => codeUnderTestInternal(arg, fun);

export default codeUnderTest;
