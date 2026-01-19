import { GraphQLCodegenDataMasking } from "@apollo/client/masking";

declare module "@apollo/client" {
  // eslint-disable-next-line @typescript-eslint/no-empty-object-type
  export interface TypeOverrides
    extends GraphQLCodegenDataMasking.TypeOverrides {}
}
