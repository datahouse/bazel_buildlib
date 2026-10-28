import Docker from "dockerode";
import { PostgreSqlContainer } from "@testcontainers/postgresql";
import {
  DockerComposeEnvironment,
  StartedDockerComposeEnvironment,
} from "testcontainers";
import path from "node:path";
import { writeFile } from "node:fs/promises";
import { dump as dumpYaml } from "js-yaml";
import { randomBytes } from "node:crypto";
import { getComposeContainerAddress } from "../src/composeContainer.js";
import loadPostgresImage from "./load_postgres_image.js";

const composeContent = (image: string) =>
  dumpYaml({
    services: {
      "pg-service": {
        image,
        environment: {
          // Required environment variable for Postgres container.
          // @testcontainers/PostgreSqlContainer handles this automatically.
          POSTGRES_PASSWORD: "example",
        },
      },
      "no-network": {
        image,
        network_mode: "none",
        // The container needs a command that keeps it running without network.
        command: ["sleep", "infinity"],
      },
    },
  });

const startCompose = async (image: string, projectName: string) => {
  const composeFileName = "docker-compose.yml";
  const tmpDir = process.env.TEST_TMPDIR!;
  await writeFile(path.join(tmpDir, composeFileName), composeContent(image));
  return await new DockerComposeEnvironment(tmpDir, composeFileName)
    // DockerComposeEnvironment generates a "fresh" project name as `testcontainers-${uuid}` but
    // does not expose it. So instead of deriving it from the container labels we set it explicitly
    .withProjectName(projectName)
    .withClientOptions({
      executable: {
        standalone: true,
        // DockerComposeEnvironment runs compose from tmpDir, so a relative
        // path to the compose binary does not resolve correctly.
        executablePath: path.resolve(process.env.COMPOSE_BIN!),
      },
    })
    .up();
};

const startDuplicateContainer = async (image: string, projectName: string) =>
  new PostgreSqlContainer(image)
    .withLabels({
      "com.docker.compose.project": projectName,
      "com.docker.compose.service": "pg-service",
      "com.docker.compose.container-number": "1",
    })
    .start();

describe("getComposeContainer", () => {
  let composeEnv: StartedDockerComposeEnvironment;
  const projectName = randomBytes(6).toString("hex");
  const docker = new Docker();

  const fakeServiceRef = {
    project: projectName,
    service: "pg-service",
    index: 1,
    port: 5432,
    composeLabel: "//test:dc",
  };

  beforeAll(
    async () => {
      const image = await loadPostgresImage();
      composeEnv = await startCompose(image, projectName);
    },
    5 * 60 * 1000,
  );

  afterAll(
    async () => {
      await composeEnv.down();
    },
    5 * 60 * 1000,
  );

  it("returns err when no container matches", async () => {
    const result = await getComposeContainerAddress(docker, {
      ...fakeServiceRef,
      index: 2,
    });

    expect(result).toEqual({
      type: "err",
      message:
        "No running container found. To start the container:\n" +
        "bazelisk run //test:dc -- up -d pg-service",
    });
  });

  it("returns ok when a container matches", async () => {
    const result = await getComposeContainerAddress(docker, fakeServiceRef);

    // <ip>:5432
    expect(result).toEqual({
      type: "ok",
      address: expect.stringMatching(/^\d+\.\d+\.\d+\.\d+:5432$/) as unknown,
    });
  });

  it("returns err when the container has no IP addresses", async () => {
    const result = await getComposeContainerAddress(docker, {
      ...fakeServiceRef,
      service: "no-network",
    });

    // Container <id> has no IP addresses.
    expect(result).toEqual({
      type: "err",
      message: expect.stringMatching(
        /^Container [0-9a-f]+ has no IP addresses\.$/,
      ) as unknown,
    });
  });

  it(
    "returns err when multiple containers match",
    async () => {
      const image = await loadPostgresImage();
      // `await using` declares a block-scoped variable that is automatically
      // disposed when out of scope. The variable is intentionally held for disposal.
      // eslint-disable-next-line @typescript-eslint/no-unused-vars
      await using duplicate = await startDuplicateContainer(image, projectName);
      const result = await getComposeContainerAddress(docker, fakeServiceRef);

      expect(result).toEqual({
        type: "err",
        message: `Expected at most 1 container for ${projectName}-pg-service-1, found 2`,
      });
    },
    5 * 60 * 1000,
  );
});
