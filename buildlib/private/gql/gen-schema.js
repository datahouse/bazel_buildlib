// Note: js file, because we cannot reasonably typecheck this:
// All dependencies must come from the user node_modules.

import "reflect-metadata";

import { emitSchemaDefinitionFile } from "type-graphql";

const { default: getSchema } = await import(process.argv[2]);

const schema = await getSchema();
await emitSchemaDefinitionFile(process.argv[3], schema);
