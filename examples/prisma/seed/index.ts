import { PrismaClient } from "../client/index.js";

const prisma = new PrismaClient();

const seed = async () => {
  // Set the dev password for the api_login user.
  await prisma.$executeRaw`ALTER ROLE api_login WITH PASSWORD 'uh0Fahth8nu1ong9phai'`;

  await prisma.user.create({
    data: {
      email: "alice@example.com",
      lists: {
        create: [
          {
            name: "Work",
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
            name: "Personal",
            archived: false,
            items: {
              create: [
                { done: false, text: "blibb" },
                { done: true, text: "blabb" },
                { done: true, text: "blubb" },
              ],
            },
          },
          {
            name: "Old TODOs",
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

try {
  await seed();
} finally {
  await prisma.$disconnect();
}
