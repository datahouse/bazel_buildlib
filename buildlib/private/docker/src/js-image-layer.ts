import { readdir, realpath, readFile } from "node:fs/promises";
import * as path from "node:path";
import argparse from "argparse";

import LayerBuilder from "./LayerBuilder";

async function* walkDirForFiles(
  walkDir: string,
  relParent: string = "",
): AsyncGenerator<string, void, void> {
  const dirents = await readdir(walkDir, { withFileTypes: true });
  for (const dirent of dirents) {
    const relPath = path.join(relParent, dirent.name);

    if (dirent.isDirectory()) {
      yield* walkDirForFiles(path.join(walkDir, dirent.name), relPath);
    } else {
      yield relPath;
    }
  }
}

interface Entry {
  srcPath: string;
  shortPath: string;
  root: string;
  isSource: boolean;
  isDirectory: boolean;
}

/** Where an entry goes inside the container. */
const trgPath = (e: Entry): string => path.join("/app", e.shortPath);

async function build(entries: Entry[], outputLayerPath: string) {
  // Note that entries can contain duplicates (by trgPath).
  // See _js_image_layer_impl for details. LayerBuilder deduplicates files if
  // they have the same srcPath.
  //
  // LayerBuilder will fail if files with different srcPath have the same
  // trgPath. This could happen in involved transition scenarios where an image
  // needs the same files from multiple bazel configurations. If this is the
  // case, the simplified layout we aim for with js-image-layer is not usable
  // (so it really should fail).

  const layer = new LayerBuilder(outputLayerPath);

  const entriesBySrc = new Map(entries.map((e) => [e.srcPath, e]));
  const sourceFiles = new Set(
    entries.filter((e) => e.isSource).map((e) => e.srcPath),
  );

  for (const entry of entries) {
    const { shortPath, srcPath, root, isDirectory, isSource } = entry;

    // it's a TreeArtifact. expand it and add individual entries.
    if (isDirectory) {
      for await (const subPath of walkDirForFiles(srcPath)) {
        await layer.addFile(
          path.join(trgPath(entry), subPath),
          path.join(srcPath, subPath),
        );
      }
    } else if (isSource) {
      // A source file from workspace, not an output of a target.
      await layer.addFile(trgPath(entry), srcPath);
    } else {
      // Find the link target (ab)-using the root:
      // bazel itself also uses symlinks so we need a way to distinguish the
      // bazel symlinks from user symlinks.
      //
      // We simply look for the root path inside the full path:
      // Since the root is usually reasonably complex (`bazel-out/k8-fastbuild-ST-4a519fd6d3e4/bin`),
      // this should be stable enough.
      //
      // Note that this can lead to duplicate links. LayerBuilder deduplicates
      // them, provided they point to the same location.

      const realSrcPath = await realpath(srcPath);
      const srcLinkTarget = realSrcPath.slice(realSrcPath.indexOf(root));

      if (srcLinkTarget !== srcPath) {
        const targetEntry = entriesBySrc.get(srcLinkTarget);
        if (targetEntry === undefined) {
          throw new Error(
            `couldn't find link target for ${srcPath} / ${realSrcPath}`,
          );
        }
        layer.addSymlink(trgPath(entry), trgPath(targetEntry));
      } else if (sourceFiles.has(shortPath)) {
        // In case a non-source file has the exact same path as a source file,
        // we assume it comes from copy_to_bin. Otherwise we'll get duplicate
        // files (which makes LayerBuilder fail) in this case (see #351).
      } else {
        await layer.addFile(trgPath(entry), srcPath);
      }
    }
  }

  layer.finalize();
}

const main = async () => {
  const parser = new argparse.ArgumentParser({
    description: "Node.js binary image layer builder",
  });

  parser.add_argument("entries", { help: "entry file (json)" });
  parser.add_argument("output", { help: "layer output (.tar.gz)" });

  const args = parser.parse_args();

  const entries = JSON.parse(await readFile(args.entries, "utf8"));

  await build(entries, args.output);
};

main().catch((err) => {
  console.log(err);
  process.exit(1);
});
