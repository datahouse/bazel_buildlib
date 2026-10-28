import { defineConfig } from "@hey-api/openapi-ts";

export default defineConfig({
  input: "./gravatar.json",
  output: {
    path: "gravatar",
    module: { extension: ".js" },
    entryFile: false,
  },
  plugins: [
    {
      name: "@hey-api/sdk",
      // disable auth code generation.
      // it's a lot of code, and most projects don't use it (but just set a Header instead).
      // if you use the auth code, remove the next line
      auth: false,
      operations: {
        strategy: "single",
        containerName: "GravatarClient",
      },
      validator: {
        response: "zod",
      },
    },
  ],
});
