load("@dh_buildlib//private/prisma:store.bzl", "prisma_engines_store")

prisma_engines_store(
    name = "engines",
    platform = "{PLATFORM}",
)
