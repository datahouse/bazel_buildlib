import { PrismaClient } from "./prisma.js";

export default interface ServerContext {
  prisma: PrismaClient;
}
