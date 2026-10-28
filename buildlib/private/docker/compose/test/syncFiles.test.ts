import {
  mkdtemp,
  rm,
  mkdir,
  writeFile,
  readdir,
  utimes,
  readFile,
  symlink,
  lutimes,
} from "node:fs/promises";

import path from "node:path";

import * as extendedMatchers from "jest-extended";

import syncFiles from "../src/syncFiles.js";

expect.extend(extendedMatchers);

describe("syncFiles", () => {
  let tmpDir: string = "";

  const srcDir = (...e: string[]): string => path.join(tmpDir, "src", ...e);
  const trgDir = (...e: string[]): string => path.join(tmpDir, "trg", ...e);

  const readTrgDir = (): Promise<string[]> =>
    readdir(trgDir(), { recursive: true });

  const touch = (p: string): Promise<void> => writeFile(p, "", { mode: 0o444 });

  beforeEach(async () => {
    tmpDir = await mkdtemp("syncFiles.test.ts");

    // Create some files / dirs.

    await mkdir(srcDir());
    await mkdir(srcDir("dir1"));
    await mkdir(srcDir("dir2"));

    await touch(srcDir("file1.txt"));
    await touch(srcDir("file2.txt"));

    await touch(srcDir("dir1", "dir1file1.txt"));
    await touch(srcDir("dir1", "dir1file2.txt"));

    await touch(srcDir("dir2", "dir2file1.txt"));
    await touch(srcDir("dir2", "dir2file2.txt"));
  });

  afterEach(async () => {
    if (tmpDir !== "") await rm(tmpDir, { recursive: true });
  });

  it("empty list of files", async () => {
    await syncFiles(srcDir(), trgDir(), []);
    expect(await readTrgDir()).toBeEmpty();
  });

  it("should copy a tree to a new directory", async () => {
    await syncFiles(srcDir(), trgDir(), [
      "file1.txt",
      "dir1/dir1file1.txt",
      "dir1/dir1file2.txt",
      "dir2/dir2file1.txt",
    ]);

    // file2.txt and dir2file2.txt must not be copied.
    expect(await readTrgDir()).toIncludeSameMembers([
      "file1.txt",
      "dir1",
      "dir1/dir1file1.txt",
      "dir1/dir1file2.txt",
      "dir2",
      "dir2/dir2file1.txt",
    ]);
  });

  it("should remove extraneous files and directories", async () => {
    await mkdir(trgDir());
    await touch(trgDir("file3.txt"));
    await mkdir(trgDir("dir3"));

    await syncFiles(srcDir(), trgDir(), ["file1.txt", "dir1/dir1file1.txt"]);

    expect(await readTrgDir()).toIncludeSameMembers([
      "file1.txt",
      "dir1",
      "dir1/dir1file1.txt",
    ]);
  });

  it("should change dirs to files", async () => {
    await mkdir(trgDir());
    await mkdir(trgDir("file1.txt"));

    await syncFiles(srcDir(), trgDir(), ["file1.txt"]);

    expect(await readTrgDir()).toIncludeSameMembers(["file1.txt"]);
  });

  it("should change files to dirs", async () => {
    await mkdir(trgDir());
    await touch(trgDir("dir1"));

    await syncFiles(srcDir(), trgDir(), ["dir1/dir1file1.txt"]);

    expect(await readTrgDir()).toIncludeSameMembers([
      "dir1",
      "dir1/dir1file1.txt",
    ]);
  });

  it("should override old files", async () => {
    await mkdir(trgDir());

    // Write different content so we can check it's overridden.
    await writeFile(trgDir("file1.txt"), "witness");
    await utimes(trgDir("file1.txt"), 0, 0); // mark the file as old

    await syncFiles(srcDir(), trgDir(), ["file1.txt"]);

    expect(await readFile(trgDir("file1.txt"), "utf8")).toEqual("");
  });

  it("should not copy older files", async () => {
    await mkdir(trgDir());

    // Ensure source file is modified in the past
    // The time resolution is too coarse for it to be enough to just create it
    // later in the control flow.
    await utimes(srcDir("file1.txt"), 0, 0);

    // Write different content to the target so we can check if it is overridden.
    await writeFile(trgDir("file1.txt"), "witness");

    await syncFiles(srcDir(), trgDir(), ["file1.txt"]);

    expect(await readFile(trgDir("file1.txt"), "utf8")).toEqual("witness");
  });

  it("should take modified time from real file (not symlink)", async () => {
    await symlink("file1.txt", srcDir("symlink.txt"));

    // Write content to trgDir so we can check it's overridden.
    await mkdir(trgDir());
    await writeFile(trgDir("symlink.txt"), "witness");

    // Set times: symlink is oldest, then the target file, real source file is new.
    await lutimes(srcDir("symlink.txt"), 0, 0);
    await utimes(trgDir("symlink.txt"), 1, 1);

    await syncFiles(srcDir(), trgDir(), ["symlink.txt"]);

    expect(await readFile(trgDir("symlink.txt"), "utf8")).toEqual("");
  });
});
