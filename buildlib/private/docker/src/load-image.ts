import { stdout } from "node:process";
import { loadImageDirToDocker } from "./loadImageToDocker.js";

const main = async () => {
  // Ignore first 2 args:
  // - The name of the node binary
  // - The path to the JS script.
  const imageDir = process.argv[2];

  const digest = await loadImageDirToDocker(imageDir);

  stdout.write(digest);
};

await main();
