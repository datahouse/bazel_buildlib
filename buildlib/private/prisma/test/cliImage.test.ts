import { GenericContainer, Wait } from "testcontainers";
import { text } from "node:stream/consumers";

import loadCliImage from "./load_cli_image.js";

const runCommand = async (...cmd: string[]) => {
  const testImage = await loadCliImage();

  const container = await new GenericContainer(testImage)
    .withWaitStrategy(Wait.forOneShotStartup())
    .withCommand(cmd)
    .start();

  return text(await container.logs());
};

describe("prisma cli container image", () => {
  // running without argument just runs prisma and prints the help output
  it(
    "default container behaviour runs prisma without arguments",
    async () => {
      const output = await runCommand();
      // this is the contained in the output for prisma 5.22.0
      //     Usage
      //
      //       $ prisma [command]
      expect(output).toMatch(/Usage\s*\$\sprisma\s\[command\]/);
    },
    5 * 60 * 1000,
  );

  // this runs prisma version; it ensures that arguments are being passed to
  // the prisma cli and the resulting output is a json object which contains a
  // prisma field which matches a version regex
  it(
    "can run prisma cli with version passed as argument",
    async () => {
      const output = await runCommand("prisma", "version", "--json");
      const parsedOutput = JSON.parse(output);
      expect(parsedOutput).toHaveProperty(
        "prisma",
        expect.stringMatching(/[0-9]+\.[0-9]+\.[0-9]+/i),
      );
    },
    5 * 60 * 1000,
  );

  // this runs format on the schema.prisma inside the container
  it(
    "can find schema.prisma and format it using prisma cli",
    async () => {
      const output = await runCommand("prisma", "format");
      // more output is generated but it contains this
      expect(output).toMatch("Formatted schema.prisma");
    },
    5 * 60 * 1000,
  );
});
