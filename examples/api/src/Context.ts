import { PrismaClient } from "../../prisma/rls/index.js";

import type { GravatarClient } from "../clients/gravatar/sdk.gen.js";

import BlobStore from "./BlobStore.js";

export default interface Context {
  prisma: PrismaClient;
  elevatedPrisma: PrismaClient;
  blobStore: BlobStore;
  gravatar: GravatarClient;
}
