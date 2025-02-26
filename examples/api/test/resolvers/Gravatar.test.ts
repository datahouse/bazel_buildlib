import { mockDeep } from "jest-mock-extended";

import type { User } from "../../../prisma/typegraphql-prisma/index.js";

import type { components } from "../../clients/gravatar-schema.js";

import Context from "../../src/Context.js";

import { GravatarResolver } from "../../src/resolvers/Gravatar.js";
import type { GravatarProfile } from "../../src/types/GravatarProfile.js";

const resolver = new GravatarResolver();

const fakeUser: User = {
  id: 1,
  // Example from the Gravatar docs (note the trailing spaces).
  email: "MyEmailAddress@example.com ",
};

// Example hash from the Gravatar docs.
const fakeHash =
  "84059b07d4be67b806386c0aad8070a23f18836bbaae342275dc0a83414c32ee";

const fakeProfile: GravatarProfile = {
  display_name: "The User",
  profile_url: "https://example.com/profile",
  avatar_url: "https://example.com/pic",
  avatar_alt_text: "The Text",
};

describe("gravatarProfile", () => {
  it("calculates the gravatar profile hash", async () => {
    const ctx = mockDeep<Context>();

    ctx.gravatar["/profiles/{profileIdentifier}"].GET.mockResolvedValue({
      // cheat a bit, we do not want to define a full profile for testing.
      data: fakeProfile as components["schemas"]["Profile"],
      response: new Response(),
    });

    await resolver.gravatarProfile(fakeUser, ctx);

    expect(
      ctx.gravatar["/profiles/{profileIdentifier}"].GET,
    ).toHaveBeenCalledWith({
      params: {
        path: { profileIdentifier: fakeHash },
      },
    });
  });

  it("returns the profile", async () => {
    const ctx = mockDeep<Context>();

    ctx.gravatar["/profiles/{profileIdentifier}"].GET.mockResolvedValue({
      // cheat a bit, we do not want to define a full profile for testing.
      data: fakeProfile as components["schemas"]["Profile"],
      response: new Response(),
    });

    await expect(resolver.gravatarProfile(fakeUser, ctx)).resolves.toEqual(
      fakeProfile,
    );
  });

  it("returns undefined on not found", async () => {
    const ctx = mockDeep<Context>();

    ctx.gravatar["/profiles/{profileIdentifier}"].GET.mockResolvedValue({
      // cast: openapi spec doesn't have error value types, but we need a value
      // to hint typing that we do not need `data` (one of data / error must be set).
      error: "Not found" as never,
      response: new Response("Not found", { status: 404 }),
    });

    await expect(
      resolver.gravatarProfile(fakeUser, ctx),
    ).resolves.toBeUndefined();
  });

  it("fails on other errors", async () => {
    const ctx = mockDeep<Context>();

    ctx.gravatar["/profiles/{profileIdentifier}"].GET.mockResolvedValue({
      // cast: openapi spec doesn't have error value types, but we need a sentinel.
      error: "Internal Error" as never,
      response: new Response("Internal Error", { status: 500 }),
    });

    await expect(resolver.gravatarProfile(fakeUser, ctx)).rejects.toThrow(
      /Internal Error/,
    );
  });
});
