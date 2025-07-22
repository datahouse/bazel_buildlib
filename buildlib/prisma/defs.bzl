"""Prisma rules.

Also see [examples/prisma/BUILD.bazel](../../examples/prisma/BUILD.bazel).
"""

load("//private/prisma:deploy_image.bzl", _prisma_deploy_image = "prisma_deploy_image")
load("//private/prisma:dev.bzl", _prisma_dev = "prisma_dev")
load("//private/prisma:generate.bzl", _prisma_generate = "prisma_generate")
load("//private/prisma:migrations.bzl", _prisma_migrations = "prisma_migrations")
load("//private/prisma:schema.bzl", _prisma_schema = "prisma_schema")

prisma_schema = _prisma_schema
prisma_generate = _prisma_generate
prisma_dev = _prisma_dev
prisma_deploy_image = _prisma_deploy_image
prisma_migrations = _prisma_migrations
