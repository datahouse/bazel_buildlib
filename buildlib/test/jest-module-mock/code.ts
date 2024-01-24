import fun from "./moduleToMock.js";

const codeUnderTest = (arg: string) => fun(arg);

export default codeUnderTest;
