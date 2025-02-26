load("@dh_buildlib//private/prisma:cli.bzl", "prisma_cli")
load("@dh_buildlib//private/prisma:constants.bzl", "PLATFORMS")

prisma_cli(
    name = "cli",
    visibility = ["//visibility:public"],
)

alias(
    name = "engines",
    actual = select({
        "@dh_buildlib//private/prisma/configs:" + platform: "@prisma_engines_" + platform + "//:engines"
        for platform in PLATFORMS.keys()
    }),
    visibility = ["//visibility:public"],
)
