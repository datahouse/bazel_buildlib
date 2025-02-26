import "reflect-metadata";

import { createHash } from "node:crypto";

import { Root, Ctx, FieldResolver, Resolver } from "type-graphql";

import type Context from "../Context.js";

import { User } from "../../../prisma/typegraphql-prisma/index.js";

import { GravatarProfile, fromREST } from "../types/GravatarProfile.js";

// Resolver that adds a gravatarProfile field to the user.
//
// Currently not used in the App, but you can play around with it in the GQL
// playground (http://api-it-bazel-examples.localhost/).
//
// Example query:
//
//     query GravatarTest {
//       users {
//         id
//         email
//         gravatarProfile {
//           display_name
//         }
//       }
//     }
//
// Note: RLS prevents you from seeing any other user than the "currently logged
// in one". At the time of writing, this is hardcoded to `alice@example.com`
// (see api/src/index.ts).
//
// If you want to retrieve your own Gravatar profile:
// - Add your e-mail address to the seed script (prisma/seed/index.ts).
// - Change the hard-coded user to your e-mail.
@Resolver(() => User)
export class GravatarResolver {
  @FieldResolver(() => GravatarProfile, { nullable: true })
  async gravatarProfile(
    @Root() user: User,
    @Ctx() { gravatar }: Context,
  ): Promise<GravatarProfile | undefined> {
    const profileIdentifier = createHash("sha256")
      .update(user.email.trim().toLowerCase())
      .digest("hex");

    const {
      data,
      error,
      response: { status },
    } = await gravatar["/profiles/{profileIdentifier}"].GET({
      params: {
        path: { profileIdentifier },
      },
    });

    if (status === 404) return undefined;

    if (!data) throw new Error(error);

    return fromREST(data);
  }
}
