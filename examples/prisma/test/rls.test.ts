import { promisify } from "node:util";
import { execFile } from "node:child_process";
import process from "node:process";

import {
  PostgreSqlContainer,
  StartedPostgreSqlContainer,
} from "@testcontainers/postgresql";

import { PrismaClient as BasePrismaClient } from "../prisma-client/index.js";
import enableRLS, { PrismaClient } from "../rls/index.js";

import loadPostgresImage from "./load_postgres_image.js";

const pushSchema = (url: string) =>
  // Invoke prisma CLI. No programmatic access for now.
  // https://github.com/prisma/prisma/issues/13549
  promisify(execFile)(
    "../prisma/cli.prisma.sh",
    ["migrate", "deploy", "--schema", "prisma/schema.prisma"],
    { env: { ...process.env, DATABASE_URL: url } },
  );

const createTestData = async (prisma: BasePrismaClient) => {
  await prisma.user.create({
    data: {
      email: "alice@example.com",
      lists: {
        create: {
          name: "alice",
          archived: false,
          items: {
            create: {
              done: false,
              text: "alice",
              attachments: {
                create: {
                  filename: "alice's file.txt",
                  mimetype: "text/plain",
                },
              },
            },
          },
        },
      },
    },
  });

  await prisma.user.create({
    data: {
      email: "bob@example.com",
      lists: {
        create: {
          name: "bob",
          archived: false,
          items: {
            create: {
              done: false,
              text: "bob",
              attachments: {
                create: {
                  filename: "bob's file.txt",
                  mimetype: "text/plain",
                },
              },
            },
          },
        },
      },
    },
  });
};

describe("RLS for alice", () => {
  let psqlContainer: StartedPostgreSqlContainer;
  let priviledgedPrisma: BasePrismaClient;
  let prisma: PrismaClient;
  let elevatedPrisma: PrismaClient;

  beforeAll(
    async () => {
      const image = await loadPostgresImage();

      psqlContainer = await new PostgreSqlContainer(image).start();

      const url = psqlContainer.getConnectionUri();

      priviledgedPrisma = new BasePrismaClient({
        datasources: { db: { url } },
      });
      ({ prisma, elevatedPrisma } = enableRLS(
        priviledgedPrisma,
        "alice@example.com",
      ));

      await Promise.all([priviledgedPrisma.$connect(), pushSchema(url)]);

      await createTestData(priviledgedPrisma);
    },
    5 * 60 * 1000 /* 5 min, pulling the image can take time */,
  );

  afterAll(async () => {
    await priviledgedPrisma.$disconnect();
    await psqlContainer.stop();
  });

  it("alice cannot see bob", async () => {
    const bob = await prisma.user.findUnique({
      where: { email: "bob@example.com" },
    });

    expect(bob).toBeNull();
  });

  it("alice can see herself", async () => {
    const alice = await prisma.user.findUnique({
      where: { email: "alice@example.com" },
    });

    expect(alice).toHaveProperty("email", "alice@example.com");
  });

  it("alice can only see her own TODOs", async () => {
    const todos = await prisma.todoItem.findMany({ select: { text: true } });
    expect(todos).toEqual([{ text: "alice" }]);
  });

  it("alice can only see her own lists", async () => {
    const todos = await prisma.todoList.findMany({ select: { name: true } });
    expect(todos).toEqual([{ name: "alice" }]);
  });

  it("supports transactions", async () => {
    const todos = await prisma.$transaction((tx) =>
      tx.todoList.findMany({ select: { name: true } }),
    );
    expect(todos).toEqual([{ name: "alice" }]);
  });

  it("alice can only see her own attachment", async () => {
    const attachments = await prisma.todoAttachment.findMany({
      select: { filename: true },
    });
    expect(attachments).toEqual([{ filename: "alice's file.txt" }]);
  });

  it("alice cannot delete any attachments", async () => {
    await expect(prisma.todoAttachment.deleteMany({})).rejects.toThrow();

    // Check nothing got deleted.
    const attachments = await prisma.todoAttachment.findMany({
      select: { filename: true },
    });

    expect(attachments).toEqual([{ filename: "alice's file.txt" }]);
  });

  it("alice cannot create attachments", async () => {
    // Get a valid ID.
    const { id: itemId } = await prisma.todoItem.findFirstOrThrow({
      select: { id: true },
    });

    await expect(
      prisma.todoAttachment.create({
        data: {
          itemId,
          filename: "test.txt",
          mimetype: "text/plain",
        },
      }),
    ).rejects.toThrow();

    // Check it actually isn't here.
    expect(
      await prisma.todoAttachment.findFirst({
        where: { filename: "test.txt" },
      }),
    ).toBeNull();
  });

  it("api for alice can cannot create attachments for bob", async () => {
    // Get a valid ID.
    const { id: itemId } = await priviledgedPrisma.todoItem.findFirstOrThrow({
      where: {
        list: {
          owner: {
            email: "bob@example.com",
          },
        },
      },
    });

    const result = elevatedPrisma.todoAttachment.create({
      data: {
        itemId,
        filename: "alices-injected-file.txt",
        mimetype: "text/plain",
      },
    });

    await expect(result).rejects.toThrow();

    // Check it actually isn't here.
    expect(
      await priviledgedPrisma.todoAttachment.findFirst({
        where: { filename: "alices-injected-file.txt" },
      }),
    ).toBeNull();
  });
});
