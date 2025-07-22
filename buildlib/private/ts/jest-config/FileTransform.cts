// eslint-disable-next-line @typescript-eslint/no-var-requires -- CJS
const { basename } = require("node:path");

/** Transforms all file imports into filenames.
 *
 *  Adopted from Create React App's (CRA) fileTransformer.js
 *
 *  Note that unlike CRA, this currently does not handle SVGR.
 *
 *  This is written in plain JavaScript, because jest expects CommonJS modules.
 *  Since we do not want to support CommonJS builds with dh_buildlib going
 *  forward (#325) we write this in plain JS (given the amount of code and the
 *  fact that it is fully tested with tests, it is not worth using TS).
 */
module.exports = {
  process(sourceText: string, sourcePath: string) {
    const filenameStr = JSON.stringify(basename(sourcePath));

    return { code: `module.exports = ${filenameStr};` };
  },
};
