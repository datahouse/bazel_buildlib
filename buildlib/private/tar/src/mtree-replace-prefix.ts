import { readFile, writeFile } from "node:fs/promises";
import path from "node:path";

import argparse from "argparse";

const parseArgs = () => {
  const parser = new argparse.ArgumentParser({
    description: "mtree prefix replacer",
  });

  parser.add_argument("--src", {
    help: "mtree file to transform",
    required: true,
  });
  parser.add_argument("--out", {
    help: "output",
    required: true,
  });
  parser.add_argument("--prefix", {
    help: "prefix to remove",
    required: true,
  });
  parser.add_argument("--replacement", {
    help: "replacement string",
    required: true,
  });

  return parser.parse_args() as {
    src: string;
    out: string;
    prefix: string;
    replacement: string;
  };
};

const main = async () => {
  const {
    src,
    out,
    prefix: rawPrefix,
    replacement: rawReplacement,
  } = parseArgs();

  // Stream processing would be much nicer, but way too hard to get right with
  // backpressure and everything.
  // If we have enough files so the *list* of the files doesn't fit in memory,
  // we can revisit this.

  const srcContent = await readFile(src, "utf8");

  // Ensure inputs are normalized path segments.
  const prefix = path.normalize(`${rawPrefix}/`);
  const replacement = path.normalize(rawReplacement);

  const newContent = srcContent
    .split("\n")
    .filter((l) => l.startsWith(prefix))
    .map((l) => l.slice(prefix.length))
    .map((l) => path.join(replacement, l))
    // Note: trailing newline is necessary: Otherwise last line gets ignored:
    // https://github.com/aspect-build/bazel-lib/blob/94d41e6849cd522fdf53a7269b585fc830fc8fe0/lib/tar.bzl#L112
    .map((l) => `${l}\n`);

  await writeFile(out, newContent);
};

main().catch((err) => {
  console.log(err);
  process.exit(1);
});
