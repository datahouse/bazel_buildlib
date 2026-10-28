import { createWriteStream } from "node:fs";
import { pipeline } from "node:stream/promises";

import { GenericContainer } from "testcontainers";

import loadImage from "./load_nginx_image.js";

const image = await loadImage();

await using container = await new GenericContainer(image)
  .withExposedPorts(80)
  .start();

const host = container.getHost();
const port = container.getMappedPort(80);

const result = await fetch(`http://${host}:${port}/index.html`);

if (!result.body) throw new Error("did not get body");

await pipeline(result.body, createWriteStream(process.argv[2]));
