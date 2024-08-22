import process from "node:process";

import { readFile } from "node:fs/promises";

import { PrismaClient, DelegateArgs } from "../../blob-auth/src/prisma.js";
import { setupApp } from "../../blob-auth/src/app.js";

import { FakePrismaData } from "./FakePrismaData.js";

const port = 8000;

// console.log is OK in server startup code.
/* eslint-disable no-console */

const loadFakePrisma = async (): Promise<PrismaClient> => {
  const data = JSON.parse(
    await readFile("/fake-prisma-data.json", "utf8"),
  ) as FakePrismaData;

  return {
    todoAttachment: {
      findUnique({ where: { uuid } }: DelegateArgs) {
        return Promise.resolve(data.todoAttachment[uuid] ?? null);
      },
    },
  };
};

const main = async () => {
  const fakePrisma = await loadFakePrisma();

  const app = setupApp(() => ({ prisma: fakePrisma }));

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

await main();
