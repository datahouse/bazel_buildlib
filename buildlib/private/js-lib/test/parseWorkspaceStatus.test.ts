import parseWorkspaceStatus from "../src/parseWorkspaceStatus.js";

describe("parseWorkspaceStatus", () => {
  it("should parse trivial data", () => {
    const data = "a b c d\nmy_key somedata\nblubb 1\n";

    expect(parseWorkspaceStatus(data)).toEqual(
      new Map([
        ["a", "b c d"],
        ["my_key", "somedata"],
        ["blubb", "1"],
      ]),
    );
  });
});
