import { PrismaClient as BasePrismaClient } from "../prisma-client";

function prepareTransaction(priviledgedPrisma: BasePrismaClient, sub: string) {
  // Use a select (instead of SET LOCAL) to:
  // - Allow the use of stored procedures.
  // - Avoid unnecessary roundtrips.
  //
  // See https://www.graphile.org/postgraphile/security/#how-it-works
  return priviledgedPrisma.$executeRaw`select \
    set_config('role', 'api', true), \
    set_config('jwt.claims.sub', ${sub}, true)`;
}

// Apply the extension.
//
// Unfortunately, the typing of Prisma extensions isn't compatible with the
// original client.
//
// Therefore, we use type inference on the return type (see the PrismaClient
// type alias below).
//
// We expose a forwarder (`enableRLS`) to have a proper return type annotation.
function enableRLSInternal(priviledgedPrisma: BasePrismaClient, sub: string) {
  // Prisma client extension that lowers its own priviledges for every query and enables RLS.
  // https://www.prisma.io/docs/concepts/components/prisma-client/client-extensions/client
  return priviledgedPrisma.$extends({
    query: {
      $allModels: {
        async $allOperations({ args, query }) {
          const [, result] = await priviledgedPrisma.$transaction([
            prepareTransaction(priviledgedPrisma, sub),
            query(args),
          ]);

          return result;
        },
      },
    },
  });
}

export type PrismaClient = ReturnType<typeof enableRLSInternal>;

export default function enableRLS(
  priviledgedPrisma: BasePrismaClient,
  sub: string,
): PrismaClient {
  return enableRLSInternal(priviledgedPrisma, sub);
}
