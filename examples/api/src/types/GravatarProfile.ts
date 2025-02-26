import { ObjectType, Field } from "type-graphql";

import type { components } from "../../clients/gravatar-schema.js";

// GraphQL type of GravatarProfile.
// It is unfortunate that this file is necessary.
// However, TypeGraphQL requires runtime data about the types. Naturally, we do
// not get that data from the type-only openapi-typescript.
//
// Therefore, for now, we duplicate the profile definition here.
// For larger models, we could generate the GraphQL type based on the OpenAPI
// definition directly.

@ObjectType()
export class GravatarProfile {
  @Field()
  display_name!: string;

  @Field()
  profile_url!: string;

  @Field()
  avatar_url!: string;

  @Field()
  avatar_alt_text!: string;
}

// Helper to convert.
// Attention: We absolutely want an object literal for GravatarProfile here.
// Otherwise we only get partial type-checking of the fields due to the non-null
// assertions.
// The non-null assertions in the fields are necesssary for TypeGraphQL.
// See https://github.com/MichalLytek/type-graphql/issues/645
export const fromREST = ({
  display_name,
  profile_url,
  avatar_url,
  avatar_alt_text,
}: components["schemas"]["Profile"]): GravatarProfile => ({
  display_name,
  profile_url,
  avatar_url,
  avatar_alt_text,
});
