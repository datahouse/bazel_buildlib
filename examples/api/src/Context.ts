import { PrismaClient } from "../../prisma/rls/index.js";
import BlobStore from "./BlobStore.js";

export default interface Context {
  prisma: PrismaClient;
  elevatedPrisma: PrismaClient;
  blobStore: BlobStore;
}
