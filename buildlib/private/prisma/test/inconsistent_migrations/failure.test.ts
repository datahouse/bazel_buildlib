import { execFileWithCode } from "../../../js-lib/src/execFileWithCode.js";

test(
  "prisma_migrations detects inconsistent migrations",
  async () => {
    const { code, stderr } = await execFileWithCode(
      process.env.TEST_UNDER_TEST!,
    );
    expect(code).toEqual(1);
    expect(stderr).toEqual(
      "Prisma migrations are not consistent with schema.prisma. Please run 'prisma migrate dev'.\n",
    );
  },
  5 * 60 * 1000 /* 5min, testing migrations is slow */,
);
