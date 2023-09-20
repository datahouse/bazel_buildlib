// TODO: Migrate to Apollo Server 4 once we can upgrade to graphql 16 (see #33).
// import { ApolloServer } from '@apollo/server';
// import { startStandaloneServer } from '@apollo/server/standalone';

import process from "process";
import http from "http";
import { writeFile } from "node:fs/promises";

import { ApolloServer } from "apollo-server-express";
import {
  ApolloServerPluginLandingPageGraphQLPlayground,
  ApolloServerPluginLandingPageProductionDefault,
  ApolloServerPluginDrainHttpServer,
} from "apollo-server-core";

import express from "express";

import getSchema from "./schema";

import enableRLS from "../../prisma/rls";
import { PrismaClient } from "../../prisma/prisma-client";

const port = 4000;

const main = async () => {
  // Test writing to the blobstore.
  await writeFile("/blob_store/a-file.txt", "the content");

  const app = express();

  const httpServer = http.createServer(app);

  const priviledgedPrisma = new PrismaClient();

  const server = new ApolloServer({
    schema: await getSchema(),
    plugins: [
      ApolloServerPluginDrainHttpServer({ httpServer }),
      process.env.GQL_ENABLE_PLAYGROUND
        ? ApolloServerPluginLandingPageGraphQLPlayground()
        : ApolloServerPluginLandingPageProductionDefault(),
    ],
    context: () => {
      // TODO: Take subject from JWT token on the request.
      const sub = "alice@example.com";
      const prisma = enableRLS(priviledgedPrisma, sub);
      return { prisma, priviledgedPrisma };
    },
  });

  await server.start();

  server.applyMiddleware({ app, path: "/" });

  await new Promise<void>((res) => {
    httpServer.listen(port, res);
  });

  // console.log is OK in server startup code.
  // eslint-disable-next-line no-console
  console.log(`gql server listening on port ${port}`);
};

main().catch((err) => {
  // console.error is OK in server startup code.
  // eslint-disable-next-line no-console
  console.error(err);
  process.exit(1);
});
