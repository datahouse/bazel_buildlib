import { join } from "node:path";
import { env } from "node:process";

// We have to load the dh_buildlib code dynamically because its relative path is
// going to be different depending on whether we run in a mode where symlinks
// can escape the sandbox:
// - If we cannot escape the sandbox, we are in the runfiles tree.
// - If we can escape the sandbox, we are directly in the bindir.
//
// Since the relative paths are different (see below), we cannot reliably
// construct an import path.
//
// Example directory layout for Prisma RLS test (`@examples//prisma/test`):
//
// - `<bindir>` denotes `execroot/_main/bazel-out/k8-fastbuild/bin`
// - `<runfiles>` denotes `<bindir>/prisma/test/test_/test.runfiles`
//
//   Runfiles:
//     - `<runfiles>/_main/prisma/test/load_postgres_image.js`
//     - `<runfiles>/dh_buildlib+/private/docker/load/src/loadImageDirToDocker.js`
//
//   Bindir:
//     - <bindir>/prisma/test/load_postgres_image.js
//       (the runfiles path symlinks to this file)
//     - <bindir>/external/dh_buildlib+/private/docker/load/src/loadImageDirToDocker.js
//
// As you can observe, the relative paths are different.

const runfiles = env.RUNFILES_DIR;
const libPath = join(runfiles, "{{ LIB }}");
const image = join(runfiles, "{{ IMAGE }}");

const load = async () => {
  const { loadImageDirToDocker } =
    typeof require !== "undefined"
      ? require(libPath) // CommonJS support for jest (#711)
      : await import(libPath);

  return loadImageDirToDocker(image);
};

export default load;
