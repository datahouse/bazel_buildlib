import { PrismaClient as RLSPrismaClient } from "../../prisma/rls/index.js";
import { PrismaClient } from "../../prisma/prisma-client/index.js";

export default interface ServerContext {
  prisma: RLSPrismaClient;
  priviledgedPrisma: PrismaClient;
}
