import { getSchemaInfo } from "../src/schemaParsing.js";

describe("getSchemaInfo", () => {
  it("gets provider and url env from schema", () => {
    const schema = `
      datasource db {
        provider = "postgresql"
        url      = env("DATABASE_URL")
      }
    `;
    expect(getSchemaInfo(schema)).toEqual({
      provider: "postgresql",
      dbUrlEnv: "DATABASE_URL",
    });
  });

  it("returns empty for empty datasource", () => {
    const schema = `
      datasource db {}
    `;
    expect(getSchemaInfo(schema)).toEqual({});
  });

  it("returns only provider when url is missing", () => {
    const schema = `
      datasource db {
        provider = "foo"
      }
    `;
    expect(getSchemaInfo(schema)).toEqual({
      provider: "foo",
    });
  });

  it("returns only provider when url is constant", () => {
    const schema = `
      datasource db {
        provider = "foo"
        url      = "postgres://fake.localhost/"
      }
    `;
    expect(getSchemaInfo(schema)).toEqual({
      provider: "foo",
    });
  });
});
