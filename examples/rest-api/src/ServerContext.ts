import { PrismaClient as RLSPrismaClient } from "../../prisma/rls";
import { PrismaClient } from "../../prisma/prisma-client";

export default interface ServerContext {
  prisma: RLSPrismaClient;
  priviledgedPrisma: PrismaClient;
}
