import { updatePnpmWorkspace } from "../src/updatePnpmWorkspace.js";

describe("updatePnpmWorkspace", () => {
  it("appends saveExact: true and hoist: false when keys absent", () => {
    const input = "allowBuilds: {}\n";
    expect(updatePnpmWorkspace(input)).toEqual({
      updated: "allowBuilds: {}\nsaveExact: true\nhoist: false\n",
    });
  });

  it("returns input unchanged when saveExact and hoist are set", () => {
    // Note: Input is deliberately in the non-default order.
    const input = "hoist: false\nsaveExact: true # a comment\n";
    expect(updatePnpmWorkspace(input)).toEqual({ updated: input });
  });

  it("appends only hoist: false when saveExact already set", () => {
    const input = "saveExact: true\n";
    expect(updatePnpmWorkspace(input)).toEqual({
      updated: "saveExact: true\nhoist: false\n",
    });
  });

  it("appends only saveExact: true when hoist already set", () => {
    const input = "hoist: false\n";
    expect(updatePnpmWorkspace(input)).toEqual({
      updated: "hoist: false\nsaveExact: true\n",
    });
  });

  it("reports problems when saveExact is false and hoist is true", () => {
    expect(updatePnpmWorkspace("saveExact: false\nhoist: true\n")).toEqual({
      problems: [
        "You must set saveExact to true in pnpm-workspace.yaml",
        "You must set hoist to false in pnpm-workspace.yaml.\nSee https://github.com/aspect-build/rules_js/blob/main/docs/pnpm.md#hoisting",
      ],
    });
  });
});
