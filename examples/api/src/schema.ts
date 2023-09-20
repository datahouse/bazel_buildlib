import "reflect-metadata";

import { GraphQLSchema } from "graphql";
import { buildSchema } from "type-graphql";
import { resolvers } from "../../prisma/typegraphql-prisma";

export default function schema(): Promise<GraphQLSchema> {
  return buildSchema({
    resolvers, // authorized through psql RLS
    validate: false,
  });
}
