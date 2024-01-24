import myVersion from "./myVersion.js";

import { PrismaClient } from "../prisma/client/index.js";

// Just some statements to use the imports above.

const client = new PrismaClient();
client.$connect().catch(() => {});

throw new Error(myVersion);
