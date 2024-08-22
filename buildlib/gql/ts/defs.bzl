"""GraphQL related rules."""

load("//private/gql:client_codegen.bzl", _gql_client_codegen = "gql_client_codegen")
load("//private/gql:schema.bzl", _gql_schema = "gql_schema")

gql_schema = _gql_schema
gql_client_codegen = _gql_client_codegen
