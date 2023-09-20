import process from "process";

// The way we run the code in here is a bit hacky:
//
// Since we want to load the node module versions of the user project (and not
// the internal ones), we copy the generator code to the (bazel) package in
// which we actually generate the schema.
//
// This means:
// - Some of the imports are not visible during TS compilation.
// - We cannot depend on any node modules in //private:node_modules in here.
//
// While this is a bit hacky, it seems to be a reasonable trade-off in terms of
// re-using infrastructure (n.b. ts_library) without overcomplicating things.

import "reflect-metadata";

// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-ignore: must come from user node_modules
import { emitSchemaDefinitionFile } from "type-graphql";

const main = async () => {
  const { default: getSchema } = await import(process.argv[2]);

  const schema = await getSchema();
  await emitSchemaDefinitionFile(process.argv[3], schema);
};

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
