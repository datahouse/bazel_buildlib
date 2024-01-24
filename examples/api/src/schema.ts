import "reflect-metadata";

import { GraphQLSchema } from "graphql";
import { buildSchema } from "type-graphql";
import { resolvers } from "../../prisma/typegraphql-prisma/index.js";

import AttachmentResolver from "./resolvers/Attachment.js";

export default function schema(): Promise<GraphQLSchema> {
  return buildSchema({
    resolvers: [...resolvers, AttachmentResolver],
    validate: false,
  });
}
