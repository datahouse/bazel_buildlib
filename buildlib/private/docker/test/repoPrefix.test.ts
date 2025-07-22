import { inferRepositoryPrefix } from "../src/repoPrefix.js";

describe("inferRepositoryPrefix", () => {
  it("top level workspace", () => {
    const got = inferRepositoryPrefix({
      DRONE_REPO_NAME: "project-TLA",
      DRONE_WORKSPACE: "/drone/src",
      BUILD_WORKSPACE_DIRECTORY: "/drone/src",
    });

    expect(got).toEqual("docker.datarepo.ch/project-tla");
  });

  it("sub workspace", () => {
    const got = inferRepositoryPrefix({
      DRONE_REPO_NAME: "project-TLA",
      DRONE_WORKSPACE: "/drone/src",
      BUILD_WORKSPACE_DIRECTORY: "/drone/src/sub",
    });

    expect(got).toEqual("docker.datarepo.ch/project-tla/sub");
  });
});
