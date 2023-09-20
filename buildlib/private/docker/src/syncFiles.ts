import path from "node:path";
import { mkdir, readdir, rm, copyFile, stat, chmod } from "node:fs/promises";
import fs, { Dirent } from "node:fs";

/** A list of file paths arranged in a tree structure for easy recursive processing. */
type FileTree = Map<string, FileTree | string>;

const makeFileTree = (files: string[]): FileTree => {
  const result: FileTree = new Map();

  files.forEach((file) => {
    const segments = file.split(path.sep);
    const basename = segments.pop()!;

    const leaf = segments.reduce((parent, segment) => {
      const subdir = parent.get(segment);

      if (!subdir) {
        const m = new Map();
        parent.set(segment, m);
        return m;
      }

      if (subdir instanceof Map) {
        return subdir;
      }

      throw new Error(`directory / file conflict at ${file}`);
    }, result);

    leaf.set(basename, file);
  });

  return result;
};

/** Syncs a FileTree to an existing directory. */
const syncToDir = async (
  srcBasePath: string,
  trgDir: string,
  fileTree: FileTree,
) => {
  const dirElems = await readdir(trgDir, { withFileTypes: true });

  const syncers = dirElems.map((elem) => {
    const want = fileTree.get(elem.name);
    fileTree.delete(elem.name); // track that we took care of this.

    const trgPath = path.join(elem.path, elem.name);

    // Mutually recursive, reference before define is unavoidable.
    // eslint-disable-next-line @typescript-eslint/no-use-before-define
    return syncElem(srcBasePath, trgPath, elem, want);
  });

  // The items remaining in fileTree are items we'll need to add.
  const creators = Array.from(fileTree).map(([name, want]) => {
    const trgPath = path.join(trgDir, name);

    // Mutually recursive, reference before define is unavoidable.
    // eslint-disable-next-line @typescript-eslint/no-use-before-define
    return syncElem(srcBasePath, trgPath, undefined, want);
  });

  await Promise.all([...syncers, ...creators]);
};

/** Syncs a FileTree to a target directory while syncing the target directory
 * itself as well. */
const syncDir = async (
  srcBasePath: string,
  trgPath: string,
  got: Dirent | undefined,
  want: FileTree,
): Promise<void> => {
  if (!got) {
    // Directory isn't present, create it, then sync.
    await mkdir(trgPath);
  } else if (!got.isDirectory()) {
    // Target is not a directory. Remove and recreate.
    await rm(trgPath);
    await mkdir(trgPath);
  }

  await syncToDir(srcBasePath, trgPath, want);
};

/** Syncs a file to a target path. */
const syncFile = async (
  srcBasePath: string,
  trgPath: string,
  got: Dirent | undefined,
  want: string,
): Promise<void> => {
  const srcFilePath = path.join(srcBasePath, want);

  if (got) {
    if (got.isDirectory()) {
      await rm(trgPath, { recursive: true });
    } else {
      const { mtime: srcMtime } = await stat(srcFilePath);

      // Technically, for the mode, we should lstat, not stat.
      // for overriding, we care about the specific path,
      // for modification time, we care about the content.
      // But since we never actually write symlinks to the target
      // directory, this is not an issue.
      const { mode, mtime: trgMtime } = await stat(trgPath);

      if (srcMtime < trgMtime) return; // file is up to date.

      // Ensure we can override the file.

      /* eslint-disable no-bitwise */
      //  (mode calculations need bitwise operators)
      if (!(mode & fs.constants.S_IWUSR)) {
        await chmod(trgPath, mode | fs.constants.S_IWUSR);
      }
      /* eslint-enable no-bitwise */
    }
  }

  await copyFile(srcFilePath, trgPath);
};

/** Syncs a directory element. */
const syncElem = async (
  srcBasePath: string,
  trgPath: string,
  got: Dirent | undefined,
  want: FileTree | string | undefined,
): Promise<void> => {
  if (!want) {
    // Target shouldn't exist.
    if (got) await rm(trgPath, { recursive: true });
  } else if (want instanceof Map) {
    // Target should be a directory.
    await syncDir(srcBasePath, trgPath, got, want);
  } else {
    // Target should be a file.
    await syncFile(srcBasePath, trgPath, got, want);
  }
};

const syncFiles = async (
  srcBasePath: string,
  trgPath: string,
  files: string[],
): Promise<void> => {
  await mkdir(trgPath, { recursive: true });

  const fileTree = makeFileTree(files);

  await syncToDir(srcBasePath, trgPath, fileTree);
};

export default syncFiles;
