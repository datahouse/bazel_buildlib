import supertest from "supertest";

import { mockDeep, DeepMockProxy } from "jest-mock-extended";

import { PrismaClient as RLSPrismaClient } from "../../prisma/rls";
import { PrismaClient } from "../../prisma/prisma-client";

import { setupApp, Console } from "../src/app";

const setupTest = () => {
  const mockConsole: DeepMockProxy<Console> = mockDeep<Console>();

  const mockPriviledgedPrisma: DeepMockProxy<PrismaClient> =
    mockDeep<PrismaClient>();
  const mockPrisma: DeepMockProxy<RLSPrismaClient> =
    mockDeep<RLSPrismaClient>();

  const app = setupApp(mockConsole, () => ({
    priviledgedPrisma: mockPriviledgedPrisma,
    prisma: mockPrisma,
  }));

  return { mockPriviledgedPrisma, mockPrisma, app };
};

describe("basic app setup", () => {
  it("should respond to requests", async () => {
    const { app } = setupTest();
    const { status } = await supertest(app).get("/api/v1/version");

    expect(status).toBe(200);
  });

  it("should 404 on unknown paths", async () => {
    const { app } = setupTest();
    const { status } = await supertest(app).get("/missing");

    expect(status).toBe(404);
  });

  it("should 422 on validation errors", async () => {
    const { app } = setupTest();
    const { status } = await supertest(app)
      .post("/api/v1/todo-lists/1/items")
      .send({ id: 5, text: "test", done: false }); // `id` is not allowed

    expect(status).toBe(422);
  });
});
