import { mockDeep, DeepMockProxy } from "jest-mock-extended";

import { FileUpload } from "graphql-upload-cjs/Upload";

import { PrismaClient } from "../../../prisma/rls/index.js";

import Context from "../../src/Context.js";

import AttachmentResolver from "../../src/resolvers/Attachment.js";

const setupPrismaTxMock = (mockPrisma: DeepMockProxy<PrismaClient>): void => {
  // Configure the $transaction method to simply invoke the body and pass the client.
  // We'll spy on it to verify transactions are used where necessary.
  mockPrisma.$transaction.mockImplementation((txFun) => txFun(mockPrisma));
};

const mockCtx = () => {
  const ctx = mockDeep<Context>();

  setupPrismaTxMock(ctx.prisma);
  setupPrismaTxMock(ctx.elevatedPrisma);

  return ctx;
};

const fakeData = () => {
  const fakeAttachment = {
    id: 1,
    itemId: 2,
    filename: "fake-filename",
    mimetype: "fake-mimetype",
    uuid: "fake-uuid",
  };

  // Hack: Abuse a completely unrelated object as a data stream.
  //
  // Ideally, we'd just use a Node.js Readable here. However, the typing of
  // FileUpload is too concrete (an fs-capacitor ReadStream). Since that class
  // has private fields, we cannot mock it.
  //
  // Luckily, we do not actually need any of the stream functionality; we only
  // need to make sure the correct object is passed on. Therefore, we just
  // create an object with a property that is unlikely to exist elsewhere and
  // check we get it back on the other side.
  const streamSentinel = {
    streamSentinelForTest: true,
  } as unknown as ReturnType<FileUpload["createReadStream"]>;

  const { filename, mimetype } = fakeAttachment;

  const fakeUpload: FileUpload = {
    filename,
    mimetype,
    encoding: "7bit", // irrelevant
    createReadStream: () => streamSentinel,
  };

  return { fakeAttachment, fakeUpload, streamSentinel };
};

const resolver = new AttachmentResolver();

describe("uploadTodoAttachment", () => {
  it("should succeed", async () => {
    // Setup doubles and fake data.
    const ctx = mockCtx();

    const { fakeAttachment, fakeUpload, streamSentinel } = fakeData();
    const { filename, mimetype, uuid, itemId } = fakeAttachment;

    // Configure doubles
    ctx.elevatedPrisma.todoAttachment.create.mockResolvedValueOnce(
      fakeAttachment,
    );

    // Run code under test.
    const result = await resolver.uploadTodoAttachment(itemId, fakeUpload, ctx);

    // Validate.
    expect(result).toEqual(fakeAttachment.id);

    expect(ctx.elevatedPrisma.todoAttachment.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: { itemId, filename, mimetype },
      }),
    );

    expect(ctx.blobStore.put).toHaveBeenCalledWith(uuid, streamSentinel);
  });

  it("should not store data if DB refuses", async () => {
    // Setup doubles and fake data.
    const ctx = mockCtx();

    const { fakeAttachment, fakeUpload } = fakeData();
    const { itemId } = fakeAttachment;
    const fakeError = new Error("error for test");

    // Configure doubles
    ctx.elevatedPrisma.todoAttachment.create.mockRejectedValueOnce(fakeError);

    // Run code under test.
    const result = resolver.uploadTodoAttachment(itemId, fakeUpload, ctx);

    // Validate.
    await expect(result).rejects.toThrow(fakeError);

    expect(ctx.blobStore.put).not.toHaveBeenCalled();
  });

  it("should rollback DB if storing the data fails", async () => {
    // Setup doubles and fake data.
    const ctx = mockCtx();

    const { fakeAttachment, fakeUpload } = fakeData();
    const { itemId } = fakeAttachment;
    const fakeError = new Error("error for test");

    // Configure doubles
    ctx.elevatedPrisma.todoAttachment.create.mockResolvedValueOnce(
      fakeAttachment,
    );
    ctx.blobStore.put.mockRejectedValueOnce(fakeError);

    // Run code under test.
    const result = resolver.uploadTodoAttachment(itemId, fakeUpload, ctx);

    // Validate.
    await expect(result).rejects.toThrow(fakeError);

    expect(ctx.blobStore.put).toHaveBeenCalled(); // confidence

    // Check the transaction rejected (once).

    expect(ctx.elevatedPrisma.$transaction).toHaveBeenCalledTimes(1);

    await expect(
      ctx.elevatedPrisma.$transaction.mock.results[0].value,
    ).rejects.toThrow(fakeError);
  });
});

describe("deleteAttachment", () => {
  it("should succeed", async () => {
    // Setup doubles and fake data.
    const ctx = mockCtx();

    const { fakeAttachment } = fakeData();
    const { id, uuid } = fakeAttachment;

    // Configure doubles
    ctx.elevatedPrisma.todoAttachment.delete.mockResolvedValueOnce(
      fakeAttachment,
    );

    // Run code under test.
    const result = await resolver.deleteAttachment(id, ctx);

    // Validate.
    expect(result).toEqual(id);

    expect(ctx.elevatedPrisma.todoAttachment.delete).toHaveBeenCalledWith({
      where: { id },
    });

    expect(ctx.blobStore.del).toHaveBeenCalledWith(uuid);
  });

  it("should not delete data if DB refuses", async () => {
    // Setup doubles and fake data.
    const ctx = mockCtx();

    const { fakeAttachment } = fakeData();
    const fakeError = new Error("error for test");

    // Configure doubles
    ctx.elevatedPrisma.todoAttachment.delete.mockRejectedValueOnce(fakeError);

    // Run code under test.
    const result = resolver.deleteAttachment(fakeAttachment.id, ctx);

    // Validate.
    await expect(result).rejects.toThrow(fakeError);

    expect(ctx.blobStore.del).not.toHaveBeenCalled();
  });
});
