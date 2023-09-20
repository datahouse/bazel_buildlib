"""Prisma rules.

Also see [examples/prisma/BUILD.bazel](../../examples/prisma/BUILD.bazel).
"""

load("//private/prisma:cli_image.bzl", _prisma_cli_image = "prisma_cli_image")
load("//private/prisma:dev.bzl", _prisma_dev = "prisma_dev")
load("//private/prisma:generate.bzl", _prisma_generate = "prisma_generate", _prisma_providers = "prisma_providers")
load("//private/prisma:schema.bzl", _prisma_schema = "prisma_schema")

prisma_schema = _prisma_schema
prisma_generate = _prisma_generate
prisma_providers = _prisma_providers
prisma_dev = _prisma_dev
prisma_cli_image = _prisma_cli_image
