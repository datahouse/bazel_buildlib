import process from "node:process";

import { PrismaClient } from "../../prisma/prisma-client/index.js";
import enableRLS from "../../prisma/rls/index.js";

import { setupApp } from "./app.js";

const port = 8000;

// console.log is OK in server startup code.
/* eslint-disable no-console */

const main = () => {
  const priviledgedPrisma = new PrismaClient();

  const app = setupApp(console, () => {
    // TODO: Take subject from JWT token on the request.
    const sub = "alice@example.com";
    const { prisma } = enableRLS(priviledgedPrisma, sub);
    return { prisma, priviledgedPrisma };
  });

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
