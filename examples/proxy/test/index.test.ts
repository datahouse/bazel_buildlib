import { Buffer } from "node:buffer";
import path from "node:path";

import supertest from "supertest";

import {
  GenericContainer,
  StartedTestContainer,
  Network,
  StartedNetwork,
} from "testcontainers";

import { FakePrismaData } from "./fake-blob-auth/FakePrismaData.js";

import loadProxyImage from "./load_proxy_image.js";
import loadFakeBlobAuthImage from "./load_fake_blob_auth_image.js";

const fakePrismaData: FakePrismaData = {
  todoAttachment: {
    // Basic case.
    "11111111-1111-1111-1111-111111111111": {
      filename: "test.png",
      mimetype: "image/png",
    },
    // Wrong extension
    "22222222-2222-2222-2222-222222222222": {
      filename: "test.gif",
      mimetype: "image/png",
    },
    // Explicit charset
    "33333333-3333-3333-3333-333333333333": {
      filename: "test.txt",
      mimetype: "text/plain; charset=us-ascii",
    },
    // No charset (nginx will add it).
    "44444444-4444-4444-4444-444444444444": {
      filename: "test.txt",
      mimetype: "text/plain",
    },
  },
};

const fakeBlobData: Record<string, Buffer> = {
  // blob for different user.
  "00/000000-0000-0000-0000-000000000000": Buffer.from([0x00, 0x01, 0x02]),
  // blobs for this user
  "11/111111-1111-1111-1111-111111111111": Buffer.from([0x03, 0x04, 0x05]),
  "22/222222-2222-2222-2222-222222222222": Buffer.from([0x06, 0x07, 0x08]),
  "33/333333-3333-3333-3333-333333333333": Buffer.from("Test ASCII", "ascii"),
  "44/444444-4444-4444-4444-444444444444": Buffer.from("Test UTF8 😊", "utf8"),
};

describe("blobstore auth", () => {
  let network: StartedNetwork;
  let proxyContainer: StartedTestContainer;
  let blobAuthContainer: StartedTestContainer;
  let proxyURL: string;

  beforeAll(
    async () => {
      network = await new Network().start();

      const fakeBlobAuthImage = loadFakeBlobAuthImage();
      const proxyImage = loadProxyImage();

      blobAuthContainer = await new GenericContainer(await fakeBlobAuthImage)
        .withNetwork(network)
        .withExposedPorts(8000) // expose the port so testcontainers waits for it to be bound.
        .withNetworkAliases("proxy-blob-auth")
        .withCopyContentToContainer([
          {
            content: JSON.stringify(fakePrismaData),
            target: "/fake-prisma-data.json",
          },
        ])
        .start();

      proxyContainer = await new GenericContainer(await proxyImage)
        .withNetwork(network)
        .withExposedPorts(80)
        .withCopyContentToContainer(
          Object.entries(fakeBlobData).map(([relPath, content]) => ({
            content,
            target: path.join("/blob_store/", relPath),
          })),
        )
        .start();

      const httpHost = proxyContainer.getHost();
      const httpPort = proxyContainer.getMappedPort(80);

      proxyURL = `http://${httpHost}:${httpPort}`;
    },
    5 * 60 * 1000 /* 5 min, loading the image can take time */,
  );

  afterAll(
    async () => {
      await Promise.all([proxyContainer?.stop(), blobAuthContainer?.stop()]);
      await network.stop();
    },
    1 * 60 * 1000 /* 1 min, docker is slow */,
  );

  it("rejects disallowed blobs", async () => {
    const { status } = await supertest(proxyURL).get(
      "/blob/todoAttachment/00000000-0000-0000-0000-000000000000",
    );

    expect(status).toEqual(403);
  });

  it("permits allowed blobs", async () => {
    const { status, headers, body } = await supertest(proxyURL)
      .get("/blob/todoAttachment/11111111-1111-1111-1111-111111111111")
      .responseType("ArrayBuffer");

    expect(status).toEqual(200);
    expect(headers).toMatchObject({
      "content-type": "image/png",
      "content-disposition": "inline; filename*=UTF-8''test.png",
    });
    expect(Buffer.from(body)).toEqual(Buffer.from([0x03, 0x04, 0x05]));
  });

  it("ignores filename extension for content-type", async () => {
    const { status, headers, body } = await supertest(proxyURL)
      .get("/blob/todoAttachment/22222222-2222-2222-2222-222222222222")
      .responseType("ArrayBuffer");

    expect(status).toEqual(200);
    expect(headers).toMatchObject({
      "content-type": "image/png",
      "content-disposition": "inline; filename*=UTF-8''test.gif",
    });
    expect(Buffer.from(body)).toEqual(Buffer.from([0x06, 0x07, 0x08]));
  });

  it("respects existing charsets on text data", async () => {
    const { status, headers, body } = await supertest(proxyURL)
      .get("/blob/todoAttachment/33333333-3333-3333-3333-333333333333")
      .responseType("ArrayBuffer");

    expect(status).toEqual(200);
    expect(headers).toMatchObject({
      "content-type": "text/plain; charset=us-ascii",
      "content-disposition": "inline; filename*=UTF-8''test.txt",
    });
    expect(Buffer.from(body).toString("ascii")).toEqual("Test ASCII");
  });

  it("adds default charset on text data", async () => {
    // This is not necessarily wanted behavior, but even after trying, we
    // couldn't get NGINX to omit the charset.
    // It's something we can live with.

    const { status, headers, body } = await supertest(proxyURL)
      .get("/blob/todoAttachment/44444444-4444-4444-4444-444444444444")
      .responseType("ArrayBuffer");

    expect(status).toEqual(200);
    expect(headers).toMatchObject({
      "content-type": "text/plain; charset=utf-8",
      "content-disposition": "inline; filename*=UTF-8''test.txt",
    });
    expect(Buffer.from(body).toString("utf8")).toEqual("Test UTF8 😊");
  });
});
