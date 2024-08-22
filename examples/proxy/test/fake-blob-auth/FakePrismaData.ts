import { BlobInfo } from "../../blob-auth/src/prisma.js";

export interface FakePrismaData {
  todoAttachment: Record<string, BlobInfo>;
}
