import { PrismaClient } from "../prisma-client";

const prisma = new PrismaClient();

const seed = async () => {
  // Set the dev password for the api_priviledged user.
  await prisma.$executeRaw`ALTER ROLE api_priviledged WITH PASSWORD 'uh0Fahth8nu1ong9phai'`;

  await prisma.user.create({
    data: {
      email: "alice@example.com",
      lists: {
        create: [
          {
            name: "my TODOs",
            archived: false,
            items: {
              create: [
                { done: false, text: "foo" },
                { done: false, text: "bar" },
                { done: true, text: "baz" },
              ],
            },
          },
          {
            name: "my old TODOs",
            archived: true,
            items: {
              create: [{ done: false, text: "get milk" }],
            },
          },
        ],
      },
    },
  });

  await prisma.user.create({
    data: {
      email: "bob@example.com",
      lists: {
        create: [
          {
            name: "my TODOs",
            archived: false,
            items: {
              create: [{ done: true, text: "text alice" }],
            },
          },
        ],
      },
    },
  });
};

const main = async () => {
  // Unfortunately, TS's Promise definition does not allow for async finally handlers.
  // https://github.com/microsoft/TypeScript/blob/0464e91c8b67579a4ed840e5783575a493c958e0/src/lib/es2018.promise.d.ts#L11
  //
  // This is despite at least MDN claiming it's allowed.
  // https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise/finally#parameters
  //
  // The wording in MDN is arguably unclear, but the spec is clear that finally is just sugar for
  // then()
  // https://github.com/microsoft/TypeScript/blob/0464e91c8b67579a4ed840e5783575a493c958e0/src/lib/es2018.promise.d.ts#L11
  try {
    await seed();
  } finally {
    await prisma.$disconnect();
  }
};

// Console is OK in CLI output.
/* eslint-disable no-console */
main().catch((e) => {
  console.error(e);
  process.exit(1);
});
