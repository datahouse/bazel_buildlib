import { promisify } from "node:util";
import { execFile } from "node:child_process";

const load = async () => {
  // Invoke image loader.
  //
  // Previous versions of this directly imported the relevant code from
  // dh_buildlib and called the relevant function (without indirecting via an
  // addtional node process).
  //
  // While that approach is definitely cleaner, it does not work with and
  // without fully hermetic builds at the same time. This is due to symlinks
  // escaping the non-hermetic bazel linux-sandbox:
  //
  // The relative directory from which we'll import the dh_buildlib code (i.e. the
  // directory this very module is seen in in the client bazel repository) is
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
  //     - `<runfiles>/dh_buildlib+/private/docker/src/loadImageToDocker.js`
  //
  //   Bindir:
  //     - <bindir>/prisma/test/load_postgres_image.js
  //       (the runfiles path symlinks to this file)
  //     - <bindir>/external/dh_buildlib+/private/docker/src/loadImageToDocker.js
  //
  // As you can observe, the relative paths are different.
  const { stdout } = await promisify(execFile)("{{ LOADER }}", ["{{ IMAGE }}"]);
  return stdout;
};

export default load;
