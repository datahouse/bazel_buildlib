import * as extendedMatchers from "jest-extended";
import { packageJsonProblems } from "../src/packageJsonProblems.js";

expect.extend(extendedMatchers);

describe("packageJsonSchema validation", () => {
  it("should pass validation for a valid package.json", () => {
    const validPackageJson = {
      type: "module",
      dependencies: {
        "some-package": "1.0.0",
      },
      devDependencies: {
        "some-dev-package": "2.0.0",
      },
    };
    const problems = packageJsonProblems(validPackageJson);
    expect(problems).toEqual([]);
  });

  it('should fail validation for an invalid package.json (missing "type")', () => {
    const invalidPackageJson = {
      dependencies: {
        "some-package": "1.0.0",
      },
      devDependencies: {
        "some-dev-package": "2.0.0",
      },
    };
    const problems = packageJsonProblems(invalidPackageJson);
    expect(problems).toEqual(['You must set `"type:" "module"`']);
  });

  it("should fail validation for non-exact version in dependencies", () => {
    const invalidPackageJson = {
      type: "module",
      dependencies: {
        "some-package": "^1.0.0",
      },
    };
    const problems = packageJsonProblems(invalidPackageJson);
    expect(problems).toEqual([
      'Dependency "some-package" does not use an exact version. Current: "^1.0.0". An exact version is necessary. See: https://docs.npmjs.com/cli/v6/using-npm/semver#versions',
    ]);
  });

  it("should pass validation with no dependencies", () => {
    const validPackageJson = {
      type: "module",
    };
    const problems = packageJsonProblems(validPackageJson);
    expect(problems).toEqual([]);
  });

  it("should return multiple problems for multiple failures", () => {
    const invalidPackageJson = {
      dependencies: {
        "package-a": "^1.0.0",
        "package-b": "~2.0.0",
      },
      devDependencies: {
        "dev-package": "latest",
      },
    };
    const problems = packageJsonProblems(invalidPackageJson);
    const expectedProblems = [
      'You must set `"type:" "module"`',
      'Dependency "package-a" does not use an exact version. Current: "^1.0.0". An exact version is necessary. See: https://docs.npmjs.com/cli/v6/using-npm/semver#versions',
      'Dependency "package-b" does not use an exact version. Current: "~2.0.0". An exact version is necessary. See: https://docs.npmjs.com/cli/v6/using-npm/semver#versions',
      'Dependency "dev-package" does not use an exact version. Current: "latest". An exact version is necessary. See: https://docs.npmjs.com/cli/v6/using-npm/semver#versions',
    ];
    expect(problems).toIncludeSameMembers(expectedProblems);
  });

  it("should fail validation if a restricted field is set", () => {
    const invalidPackageJson = {
      type: "module",
      description: "Some description",
    };
    const problems = packageJsonProblems(invalidPackageJson);
    expect(problems).toEqual([
      "Do not set `description`: it is only relevant for publishing npm packages which is unsupported.",
    ]);
  });
});
