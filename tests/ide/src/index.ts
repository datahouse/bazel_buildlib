import myVersion from "./myVersion.js";

import { PrismaClient } from "../prisma/client/index.js";

// Just some statements to use the imports above.

const client = new PrismaClient();
await client.$connect();

throw new Error(myVersion);
