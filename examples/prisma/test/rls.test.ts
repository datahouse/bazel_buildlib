import { promisify } from "node:util";
import { execFile } from "node:child_process";
import process from "node:process";

import {
  PostgreSqlContainer,
  StartedPostgreSqlContainer,
} from "@testcontainers/postgresql";

import { PrismaClient as BasePrismaClient } from "../prisma-client";
import enableRLS, { PrismaClient } from "../rls";

import postgresInfo from "./postgres-info.json";

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
            create: { done: false, text: "alice" },
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
            create: { done: false, text: "bob" },
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

  beforeAll(
    async () => {
      psqlContainer = await new PostgreSqlContainer(
        postgresInfo.reference,
      ).start();

      const url = psqlContainer.getConnectionUri();

      priviledgedPrisma = new BasePrismaClient({
        datasources: { db: { url } },
      });
      prisma = enableRLS(priviledgedPrisma, "alice@example.com");

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
});
