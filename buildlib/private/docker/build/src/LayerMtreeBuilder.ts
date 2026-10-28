import { strict as assert } from "node:assert";
import { stat } from "node:fs/promises";
import * as path from "node:path";

// mtree(8) keyword=value tokens are whitespace-separated, so any space in a
// path needs escaping. See vis(3) - bsdtar decodes the same \NNN octal
// escapes on read.
//
// mtree(8) BSD: https://man.netbsd.org/mtree.8
// vis(3) BSD: https://man.netbsd.org/vis.3
const escapeSpace = (s: string): string => s.replace(/ /g, "\\040");

/** Tracks the files/dirs/symlinks of a layer, deduplicating by path, and produces the mtree(8) lines describing it. */
export default class LayerMtreeBuilder {
  private lines: string[] = [];

  private files = new Map<string, string>();

  private dirs = new Set<string>();

  private symlinks = new Map<string, string>();

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
      this.addMtreeLine(dir, 0o755, "type=dir");
    }
  }

  async addFile(trgPath: string, srcPath: string): Promise<void> {
    const { mode } = await stat(srcPath);

    // Run after await to ensure atomicity with pushing the mtree line.
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

    this.addMtreeLine(
      trgPath,
      // Only keep executable bits from actual file.
      // eslint-disable-next-line no-bitwise
      (mode & 0o111) | 0o644,
      `type=file content=${escapeSpace(srcPath)}`,
    );
  }

  addSymlink(trgPath: string, linkTrg: string): void {
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

    this.addMtreeLine(trgPath, 0o755, `type=link link=${escapeSpace(linkTrg)}`);
  }

  result(): string[] {
    return this.lines;
  }

  private addMtreeLine(
    absTrgPath: string,
    mode: number,
    typeAttrs: string,
  ): void {
    assert(path.isAbsolute(absTrgPath));

    const trgPath = absTrgPath.substring(1); // strip leading '/'
    const modeStr = mode.toString(8).padStart(4, "0");

    const line = `${escapeSpace(trgPath)} uid=0 gid=0 time=0 mode=${modeStr} ${typeAttrs}`;
    this.lines.push(line);
  }
}
