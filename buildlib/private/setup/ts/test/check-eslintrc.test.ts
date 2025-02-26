import * as extendedMatchers from "jest-extended";
import { checkEslintrc } from "../src/eslintrcProblems.js";

expect.extend(extendedMatchers);

describe("eslintrc validation", () => {
  it("should fail when `root` is not set to true", () => {
    const invalidEslintrc = { extends: "./bazel-bin/eslintrc.dh-defaults.cjs" };
    const problems = checkEslintrc(invalidEslintrc);
    expect(problems).toEqual(["You must set `root: true` in .eslintrc"]);
  });

  it("should pass for a valid `.eslintrc`", () => {
    const validEslintrc = {
      root: true,
      extends: ["some/other/config", "./bazel-bin/eslintrc.dh-defaults.cjs"],
    };
    const problems = checkEslintrc(validEslintrc);
    expect(problems).toEqual([]);
  });

  it("should fail when `extends` is missing", () => {
    const invalidEslintrc = { root: true };
    const problems = checkEslintrc(invalidEslintrc);
    expect(problems).toEqual([
      ".eslintrc must extend ./bazel-bin/eslintrc.dh-defaults.cjs",
    ]);
  });

  it("should return multiple problems when `extends` is an array that does not include `baseConfigPath` and `root` is not set to true", () => {
    const invalidEslintrc = {
      root: false,
      extends: ["some/other/config", "another/config"],
    };
    const problems = checkEslintrc(invalidEslintrc);
    expect(problems).toIncludeSameMembers([
      ".eslintrc must extend ./bazel-bin/eslintrc.dh-defaults.cjs",
      "You must set `root: true` in .eslintrc",
    ]);
  });
});
