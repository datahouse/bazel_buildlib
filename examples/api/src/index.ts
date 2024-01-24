// TODO: Migrate to Apollo Server 4 once we can upgrade to graphql 16 (see #33).
// import { ApolloServer } from '@apollo/server';
// import { startStandaloneServer } from '@apollo/server/standalone';

import process from "process";
import http from "http";

import { ApolloServer } from "apollo-server-express";
import {
  ApolloServerPluginLandingPageGraphQLPlayground,
  ApolloServerPluginLandingPageProductionDefault,
  ApolloServerPluginDrainHttpServer,
} from "apollo-server-core";

import express from "express";

import graphqlUploadExpress from "graphql-upload-cjs/graphqlUploadExpress";

import getSchema from "./schema.js";

import Context from "./Context.js";
import BlobStore from "./BlobStore.js";

import enableRLS from "../../prisma/rls/index.js";
import { PrismaClient } from "../../prisma/prisma-client/index.js";

const port = 4000;

const main = async () => {
  const app = express();

  const httpServer = http.createServer(app);

  const blobStore = new BlobStore("/blob_store");
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
      const { prisma, elevatedPrisma } = enableRLS(priviledgedPrisma, sub);
      return { prisma, elevatedPrisma, blobStore } satisfies Context;
    },
    // Required for uploads to be secure.
    //
    // Why: Uploads require to accept requests with:
    //
    //   Content-Type: multipart/form-data
    //
    // However, these are
    // [simple requests](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS#simple_requests)
    // so browsers will not do a preflight request (which is bad).
    //
    // Attention: If you activate this, in calling clients, you need to set:
    //
    //   headers: {
    //     "Apollo-Require-Preflight": "true",
    //   }
    //
    // This header prevents the request from being simple and forces a pre-flight.
    //
    // For more, see https://www.apollographql.com/docs/router/configuration/csrf/
    csrfPrevention: true,
  });

  await server.start();

  // Enable upload middleware.
  // Only needed if you need uploads.
  app.use(graphqlUploadExpress());

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
