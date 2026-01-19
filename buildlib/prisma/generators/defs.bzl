"""Prisma generator rules.

For information about how to use prisma generator rules, please consult
the documentation of [`prisma_generate`](./prisma.md#prisma_generate)
"""

load("//private/prisma/generators:prisma_client.bzl", _prisma_client = "prisma_client")
load("//private/prisma/generators:prisma_client_js.bzl", _prisma_client_js = "prisma_client_js")
load("//private/prisma/generators:typegraphql_prisma.bzl", _typegraphql_prisma = "typegraphql_prisma")

typegraphql_prisma = _typegraphql_prisma
prisma_client = _prisma_client
prisma_client_js = _prisma_client_js
