import process from "node:process";
import http from "node:http";

// Unfortunately, we cannot use:
//
//   import { startStandaloneServer } from '@apollo/server/standalone';
//
// because we need express middlewares for:
//
// - file uploads
// - the GraphQL playground
//
// Therefore, we use express and the apollo express middleware.

import express from "express";

import { ApolloServer } from "@apollo/server";
import { expressMiddleware } from "@as-integrations/express5";
import { ApolloServerPluginDrainHttpServer } from "@apollo/server/plugin/drainHttpServer";

import expressGQLPlayground from "graphql-playground-middleware-express";

import { createPathBasedClient } from "openapi-fetch";

import graphqlUploadExpress from "graphql-upload/graphqlUploadExpress.mjs";

import type { paths as GravatarPaths } from "../clients/gravatar-schema.js";

import getSchema from "./schema.js";

import Context from "./Context.js";
import BlobStore from "./BlobStore.js";

import enableRLS from "../../prisma/rls/index.js";
import { PrismaClient } from "../../prisma/client/index.js";

const port = 4000;

const main = async () => {
  const app = express();

  // void to cast express 5 promise result type away.
  const httpServer = http.createServer((req, res) => void app(req, res));

  const blobStore = new BlobStore("/blob_store");
  const priviledgedPrisma = new PrismaClient();
  const gravatar = createPathBasedClient<GravatarPaths>({
    baseUrl: "https://api.gravatar.com/v3",
  });

  const server = new ApolloServer<Context>({
    schema: await getSchema(),
    plugins: [ApolloServerPluginDrainHttpServer({ httpServer })],
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

  const context = (): Promise<Context> => {
    // TODO: Take subject from JWT token on the request.
    const sub = "alice@example.com";
    const { prisma, elevatedPrisma } = enableRLS(priviledgedPrisma, sub);

    return Promise.resolve({ prisma, elevatedPrisma, blobStore, gravatar });
  };

  await server.start();

  // Enable upload middleware.
  // Only needed if you need uploads.
  app.use(graphqlUploadExpress());

  // Enable json parsing
  app.use(express.json());

  if (process.env.GQL_ENABLE_PLAYGROUND) {
    const middleware = expressGQLPlayground.default({
      endpoint: "/gql/v1/graphql",
    });
    app.get("/", middleware);
  }

  app.use("/gql/v1", expressMiddleware(server, { context }));

  await new Promise<void>((res) => {
    httpServer.listen(port, res);
  });

  // console.log is OK in server startup code.
  // eslint-disable-next-line no-console
  console.log(`gql server listening on port ${port}`);
};

await main();
