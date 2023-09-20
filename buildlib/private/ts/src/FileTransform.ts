import { basename } from "node:path";
import { SyncTransformer } from "@jest/transform";

/** Transforms all file imports into filenames.
 *
 *  Adopted from Create React App's (CRA) fileTransformer.js
 *
 *  Note that unlike CRA, this currently does not handle SVGR.
 */
const transformer: SyncTransformer = {
  process(sourceText: string, sourcePath: string) {
    const filenameStr = JSON.stringify(basename(sourcePath));

    return { code: `module.exports = ${filenameStr};` };
  },
};

export default transformer;
