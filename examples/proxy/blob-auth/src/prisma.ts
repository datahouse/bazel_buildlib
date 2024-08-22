// Narrowed-down interfaces for prisma.
// Since we need to fake these interfaces in a container (for the integration
// test fake in //proxy/test/fake-blob-auth), we define our Prisma interfaces
// rather than using the generated ones.
//
// This allows us to use the typechecker to ensure we're actually faking what we
// need (while not having to build a full prisma fake).
//
// Note that these are (and should) remain Prisma compatible. So the generated
// Prisma client can be used as the type `PrismaClient`. This means the
// interfaces simply restrict what downstream code can do with the generated
// prisma client.

// Information we expect to get about a blob.
export interface BlobInfo {
  filename: string;
  mimetype: string;
}

// Arguments we pass to a Delegate
// (the object we can call query methods like findUnique on).
export interface DelegateArgs {
  where: { uuid: string };
  select: {
    filename: true;
    mimetype: true;
  };
}

// A Prisma delegate for a specific blob type (e.g. attachments).
export interface PrismaDelegate {
  findUnique: (args: DelegateArgs) => Promise<BlobInfo | null>;
}

// The top-level prisma interface with the delegates we use.
export interface PrismaClient {
  todoAttachment: PrismaDelegate;
}
