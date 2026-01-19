import { PrismaClient } from "../prisma/client/client.js";

const prisma = new PrismaClient();

await prisma.$connect();
