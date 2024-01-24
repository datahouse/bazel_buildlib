import path from "node:path";
import { tmpdir } from "node:os";

import { mkdtemp, rm, readFile, readdir } from "node:fs/promises";

import { Readable } from "node:stream";

import * as extendedMatchers from "jest-extended";

import BlobStore from "../src/BlobStore.js";

expect.extend(extendedMatchers);

const fakeUUID = "79483bdf-5cc0-4001-900f-f75c76d622e2";
const fakeRelPath = "79/483bdf-5cc0-4001-900f-f75c76d622e2";

describe("BlobStore", () => {
  let rootForTest: string;
  let blobStore: BlobStore;

  beforeEach(async () => {
    rootForTest = await mkdtemp(path.join(tmpdir(), "BlobStore.test.ts-"));
    blobStore = new BlobStore(rootForTest);
  });

  afterEach(async () => {
    if (rootForTest) await rm(rootForTest, { recursive: true });
  });

  it("should write to the directory", async () => {
    const fakeContent = "file content. Non-ACSII: äöü";

    const stream = Readable.from(fakeContent);

    await blobStore.put(fakeUUID, stream);

    expect(stream.closed).toBeTruthy();

    const expectedPath = path.join(rootForTest, fakeRelPath);

    expect(await readFile(expectedPath, "utf8")).toEqual(fakeContent);
  });

  it("should check the UUID for length", async () => {
    await expect(blobStore.put("too-short", Readable.from(""))).rejects.toThrow(
      /expected uuid of length 36, got 'too-short'/,
    );
  });

  it("should close the inStream on failure", async () => {
    const stream = Readable.from("");

    await expect(blobStore.put("too-short", stream)).rejects.toThrow();

    expect(stream.closed).toBeTruthy();
  });

  it("should refuse to override a file", async () => {
    // Write to the store.
    await blobStore.put(fakeUUID, Readable.from("content"));

    // Try to override
    await expect(
      blobStore.put(fakeUUID, Readable.from("other content")),
    ).rejects.toThrow(/^EEXIST:/);

    // Check file content is unchanged.
    const expectedPath = path.join(rootForTest, fakeRelPath);
    expect(await readFile(expectedPath, "utf8")).toEqual("content");
  });

  it("should delete a file", async () => {
    await blobStore.put(fakeUUID, Readable.from("content"));

    await blobStore.del(fakeUUID);

    const dirContent = await readdir(rootForTest, {
      recursive: true,
      withFileTypes: true,
    });

    // Subdirectories are not cleaned up, only files.
    expect(dirContent).toSatisfyAll((d) => d.isDirectory());
  });

  it("should fail to delete a non-existent file", async () => {
    await expect(blobStore.del(fakeUUID)).rejects.toThrow(/^ENOENT:/);
  });
});
