import assert from "node:assert/strict";
import path from "node:path";

import { Readable } from "node:stream";

import { pipeline } from "node:stream/promises";
import { createWriteStream } from "node:fs";
import { mkdir, unlink } from "node:fs/promises";

/** Naive implementation of a write-once blob store.
 *
 *  ## (Known) Shortcomings
 *
 *  It does not handle write failures properly (will happily write and leave a
 *  partial file). For write-once stores this is somehwat OK (in the worst case
 *  a failed upload leaves some garbage).
 *
 *  Further, it also does not offer healthchecks (e.g. if the target filesystem
 *  is available and writeable). This can lead to setup problems being detected
 *  late (e.g. when a file is written as opposed to server startup).
 *
 *  ## UUID Generation strategy
 *
 *  In isolation, a better approach would be to let the store generate the
 *  UUIDs. This would ensure locally that they are correct / of the correct type.
 *
 *  However, when combined with RLS, the picture is a bit different:
 *
 *  Pushing the generation of the UUID to the DB let's us have both:
 *
 *  - RLS to verify whether a user is allowed to upload a file.
 *  - Do not make UUIDs in the relevant DB table nullable.
 *
 *  If the blob store generates the UUID, we'd have to either:
 *
 *  - Temporarily write a DB row without a UUID.
 *  - Write to the blob store and then perform an ACL check.
 *
 *  Both of these are worse than simply pushing the UUID down.
 */
export default class BlobStore {
  constructor(private root: string) {}

  async put(uuid: string, inStream: Readable): Promise<void> {
    try {
      const storePath = this.path(uuid);

      await mkdir(path.dirname(storePath), { recursive: true });

      // Note: `pipeline` cleans up all streams.
      await pipeline(
        inStream,
        createWriteStream(storePath, {
          flags: "wx", // disallow overriding an existing file.
        }),
      );
    } finally {
      inStream.destroy();
    }
  }

  del(uuid: string): Promise<void> {
    return unlink(this.path(uuid));
  }

  private path(uuid: string) {
    assert(uuid.length === 36, `expected uuid of length 36, got '${uuid}'`);
    return path.join(this.root, uuid.substring(0, 2), uuid.substring(2));
  }
}
