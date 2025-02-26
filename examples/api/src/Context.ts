import type { PathBasedClient } from "openapi-fetch";

import { PrismaClient } from "../../prisma/rls/index.js";

import type { paths as GravatarPaths } from "../clients/gravatar-schema.js";

import BlobStore from "./BlobStore.js";

export type GravatarClient = PathBasedClient<GravatarPaths>;

export default interface Context {
  prisma: PrismaClient;
  elevatedPrisma: PrismaClient;
  blobStore: BlobStore;
  gravatar: GravatarClient;
}
