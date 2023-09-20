import fun from "./moduleToMock";

const codeUnderTest = (arg: string) => fun(arg);

export default codeUnderTest;
