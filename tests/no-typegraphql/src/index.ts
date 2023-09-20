import process from "node:process";

import { PrismaClient } from "../prisma/client";

const prisma = new PrismaClient();

prisma.$connect().catch((err) => {
  // console.error is OK for the example.
  // eslint-disable-next-line no-console
  console.error(err);
  process.exit(1);
});
