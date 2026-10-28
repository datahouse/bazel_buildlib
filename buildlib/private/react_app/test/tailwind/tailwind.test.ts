import { readFile } from "node:fs/promises";

describe("react_app with tailwind", () => {
  it("compiles the utilities of the registered sources only", async () => {
    const css = await readFile(
      "private/react_app/test/tailwind/app.css",
      "utf8",
    );
    expect(css).toContain("margin-top:13px"); // src/main.ts
    expect(css).toContain("margin-bottom:27px"); // dep/dep.ts
    expect(css).toContain("padding-top:31px"); // index.html
    expect(css).not.toContain("margin-left:37px"); // unregistered/, imported by src/main.ts
  });
});
