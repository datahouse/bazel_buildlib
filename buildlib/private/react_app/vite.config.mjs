// vite.config.js
import process from "node:process";
import path from "node:path";

import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

const bazelSandboxRemap = (filePath) => {
  // Example: <outputBase>/sandbox/linux-sandbox/265/execroot/_main
  // Where <outputBase>: /home/tos/.cache/bazel/_bazel_tos/6dee2ad5050cbccc5636949d0df6a490
  // See https://bazel.build/remote/output-directories#layout-diagram
  const sandboxExecroot = process.env.JS_BINARY__EXECROOT;
  // Example: bazel-out/k8-fastbuild/bin
  const bindir = process.env.BAZEL_BINDIR;

  // don't touch relative paths
  if (!path.isAbsolute(filePath)) return filePath;

  const filePathInSandbox = filePath.startsWith(sandboxExecroot); // poor-man's isParent.
  // If already in sandbox --> done.
  if (filePathInSandbox) return filePath;

  // Path got mapped outside of bazel sandbox.
  // See: https://github.com/vitejs/vite/issues/21955
  //
  // filePath looks like this:
  //
  //   <outputBase>/execroot/_main/<bindir>/<short_path>
  //
  // But we need:
  //
  //   <outputBase>/sandbox/linux-sandbox/265/execroot/_main/<bindir>/<short_path>
  //
  // Where <short_path> is something like: `private/react_app/test/index.html`
  //
  // Fix it by finding the bindir (`bazel-out/k8-fastbuild/bin`) and re-map.
  //
  // This is not very nice, but we do not know the real execroot, because the rest
  // of the system hides it from us (including Node.js' `realpath` function).
  //
  // Therefore, we cannot perform full relativization of filePath so this is our
  // only option. Note that the bindir path is very bazel specific so it is
  // highly unlikely that it will appear elsewhere.

  const bindirIdx = filePath.indexOf(bindir);

  if (bindirIdx === -1) {
    throw new Error(
      `got absolute chunk path outside of bindir (${bindir}):\n${filePath}`,
    );
  }

  const execrootRelative = filePath.slice(bindirIdx);
  return path.join(sandboxExecroot, execrootRelative);
};

const bazelSandboxPlugin = {
  name: "bazel-sandbox",
  enforce: "pre",
  async resolveId(source, importer, options) {
    const resolved = await this.resolve(source, importer, options);

    if (resolved && !resolved.external) {
      resolved.id = bazelSandboxRemap(resolved.id);
    }
    return resolved;
  },
};

// @vite-ignore: without it, vite's config bundling resolves the specifier
// even when tailwind is off and warns that the dep is missing.
const tailwindPlugin =
  process.env.DH_BUILDLIB_REACT_APP_TAILWIND === "1"
    ? (await import(/* @vite-ignore */ "@tailwindcss/vite")).default()
    : null;

// Config for building (in bazel sandbox).
const buildConfig = {
  plugins: [
    react(),
    tailwindPlugin,
    bazelSandboxPlugin, // workaround for https://github.com/vitejs/vite/issues/21955
  ],
};

// Config for dev server (inside docker container).
const devServerConfig = {
  plugins: [react(), tailwindPlugin],
  // Use global tmp dir: The directory with the source files is not writeable.
  cacheDir: "/tmp/.vite",
  // Run on port 80 so we do not need to change the proxy config from nginx.
  server: {
    port: 80,
    strictPort: true,
    fs: {
      // Explicitly set serving allow list, do not rely on auto-detection.
      allow: ["/app/node_modules/", "/app/hot/"],
    },
  },
};

export default defineConfig(({ command }) => {
  switch (command) {
    case "build":
      return buildConfig;
    case "serve":
      return devServerConfig;
    default:
      throw new Error(`unexpected vite command ${command}`);
  }
});
