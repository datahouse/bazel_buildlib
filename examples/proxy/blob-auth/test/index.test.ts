import supertest from "supertest";

import { mockDeep, DeepMockProxy } from "jest-mock-extended";

import { PrismaClient } from "../src/prisma.js";
import { setupApp } from "../src/app.js";

const setupTest = () => {
  const mockPrisma: DeepMockProxy<PrismaClient> = mockDeep<PrismaClient>();

  const app = setupApp(() => ({
    prisma: mockPrisma,
  }));

  return { mockPrisma, app };
};

const fakeUUID = "fb0598f1-129c-4fea-a273-526396b37bb5";

describe("authentication", () => {
  it("should refuse access to unknown attachment", async () => {
    const { app, mockPrisma } = setupTest();

    mockPrisma.todoAttachment.findUnique.mockResolvedValue(null);

    const { status } = await supertest(app).get(
      "/todoAttachment/fb0598f1-129c-4fea-a273-526396b37bb5",
    );

    expect(status).toBe(403);

    // Check we checked the right UUID.
    expect(mockPrisma.todoAttachment.findUnique).toHaveBeenCalledTimes(1);
    expect(mockPrisma.todoAttachment.findUnique).toHaveBeenCalledWith(
      expect.objectContaining({ where: { uuid: fakeUUID } }),
    );
  });

  it("should allow access to known attachment", async () => {
    const { app, mockPrisma } = setupTest();

    mockPrisma.todoAttachment.findUnique.mockResolvedValue({
      filename: "fake.png",
      mimetype: "image/png",
    });

    const { status, headers } = await supertest(app).get(
      "/todoAttachment/fb0598f1-129c-4fea-a273-526396b37bb5",
    );

    expect(status).toBe(204);
    expect(headers).toMatchObject({
      "content-type": "image/png",
      "content-disposition": "inline; filename*=UTF-8''fake.png",
    });

    // Check we checked the right UUID.
    expect(mockPrisma.todoAttachment.findUnique).toHaveBeenCalledTimes(1);
    expect(mockPrisma.todoAttachment.findUnique).toHaveBeenCalledWith(
      expect.objectContaining({ where: { uuid: fakeUUID } }),
    );
  });

  it("should sanitize mimetype header", async () => {
    const { app, mockPrisma } = setupTest();

    // This should not happen (the DB should never contain a broken mimetype).
    // But if it does, it is paramount that we do no allow header injection.
    mockPrisma.todoAttachment.findUnique.mockResolvedValue({
      filename: "fake.png",
      mimetype: "image/png\nX-Injected-Header: foo",
    });

    const { status } = await supertest(app).get(
      "/todoAttachment/fb0598f1-129c-4fea-a273-526396b37bb5",
    );

    expect(status).toBe(500);
  });

  it("should encode filename header", async () => {
    const { app, mockPrisma } = setupTest();

    mockPrisma.todoAttachment.findUnique.mockResolvedValue({
      filename: '  " / \\.🧌',
      mimetype: "application/octet-stream",
    });

    const { status, headers } = await supertest(app).get(
      "/todoAttachment/fb0598f1-129c-4fea-a273-526396b37bb5",
    );

    expect(status).toBe(204);
    expect(headers).toMatchObject({
      "content-type": "application/octet-stream",
      "content-disposition":
        "inline; filename*=UTF-8''%20%20%22%20%2F%20%5C.%F0%9F%A7%8C",
    });
  });
});
