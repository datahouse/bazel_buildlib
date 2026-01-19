import process from "node:process";

import { ErrorRequestHandler } from "express";

import { PrismaClient } from "../../../prisma/client/index.js";
import enableRLS from "../../../prisma/rls/index.js";

import { setupApp } from "./app.js";

const port = 8000;

// console.log is OK in server startup code.
/* eslint-disable no-console */

// Very basic error handler:
// This is a completely internal API (only called from the proxy)
// so no point in being fancy.
const errorHandler: ErrorRequestHandler =
  // We must define next for express to interpret this as ErrorRequestHandler
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  (err: unknown, req, res, next) => {
    console.error(`Internal Error for ${req.path}:`, err);
    res.status(500).end();
  };

const main = () => {
  const priviledgedPrisma = new PrismaClient();

  const app = setupApp(() => {
    // TODO: Take subject from JWT token on the request.
    const sub = "alice@example.com";
    const { prisma } = enableRLS(priviledgedPrisma, sub);
    return { prisma };
  });

  app.use(errorHandler);

  const server = app.listen(port, () => {
    console.log(`REST server listening on port ${port}`);
  });

  process.on("SIGTERM", () => {
    console.log("SIGTERM received: shutting down");
    server.close(() => {
      console.log("Graceful shutdown completed");
    });
  });
};

main();
