import { PrismaClient } from "../prisma/client/index.js";

const prisma = new PrismaClient();

await prisma.$connect();
