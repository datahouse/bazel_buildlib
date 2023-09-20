import { strict as assert } from "node:assert";
import { createGzip } from "node:zlib";
import { createWriteStream, createReadStream } from "node:fs";
import { stat } from "node:fs/promises";
import * as path from "node:path";

import tar from "tar-stream";

const MTIME = new Date(0);

export default class LayerBuilder {
  private pkg = tar.pack();

  private files = new Map<string, string>();

  private dirs = new Set<string>();

  private symlinks = new Map<string, string>();

  constructor(tarPath: string) {
    this.pkg.pipe(createGzip()).pipe(createWriteStream(tarPath));
  }

  private ensureParentDirs(trgPath: string): void {
    const parents: string[] = [];
    let curDir = path.dirname(trgPath); // trgPath is a file.

    while (curDir !== "/") {
      if (this.dirs.has(curDir)) break; // ancestor exists. done.

      assert(!this.files.has(curDir));
      assert(!this.symlinks.has(curDir));

      // unshift to reverse order: parent dirs first.
      parents.unshift(curDir);
      curDir = path.dirname(curDir);
    }

    for (const dir of parents) {
      this.dirs.add(dir);
      this.pkg
        .entry({
          type: "directory",
          name: dir.substring(1), // strip leading '/'
          mode: 0o755,
          mtime: MTIME,
        })
        .end();
    }
  }

  async addFile(trgPath: string, srcPath: string): Promise<void> {
    assert(path.isAbsolute(trgPath));

    const { mode, size } = await stat(srcPath);

    // Run after await to ensure atomicity with pkg.entry.
    assert(!this.symlinks.has(trgPath));
    assert(!this.dirs.has(trgPath));

    // Dedupliate files (if they agree).
    const existing = this.files.get(trgPath);
    if (existing !== undefined) {
      assert(
        existing === srcPath,
        `conflicting files at ${trgPath}: ${existing} and ${srcPath}`,
      );
      return;
    }

    this.ensureParentDirs(trgPath);
    this.files.set(trgPath, srcPath);

    await new Promise<void>((resolve, reject) => {
      const entry = this.pkg.entry(
        {
          type: "file",
          name: trgPath.substring(1), // strip leading '/'
          mode,
          size,
          mtime: MTIME,
        },
        (err) => {
          if (err) reject(err);
          else resolve();
        },
      );
      createReadStream(srcPath).pipe(entry);
    });
  }

  addSymlink(trgPath: string, linkTrg: string): void {
    assert(path.isAbsolute(trgPath));

    assert(!this.files.has(trgPath));
    assert(!this.dirs.has(trgPath));

    // Deduplicate symlinks (if they agree).
    const existing = this.symlinks.get(trgPath);
    if (existing !== undefined) {
      assert(existing === linkTrg);
      return;
    }

    this.ensureParentDirs(trgPath);
    this.symlinks.set(trgPath, linkTrg);

    this.pkg
      .entry({
        type: "symlink",
        name: trgPath.substring(1), // strip leading '/'
        linkname: linkTrg,
        mode: 0o755,
        mtime: MTIME,
      })
      .end();
  }

  finalize(): void {
    this.pkg.finalize();
  }
}
