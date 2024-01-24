"""Datahouse buildib setup stage 2."""

load("@dh_buildlib_private_npm//:repositories.bzl", _private_npm_repositories = "npm_repositories")
load("@npm//:repositories.bzl", "npm_repositories")
load("//private/prisma:repositories.bzl", "prisma_setup")

visibility("public")

def dh_buildlib_setup2(enable_prisma = False):
    """Datahouse buildib setup stage 2.

    Args:
      enable_prisma: Whether prisma should be enabled (requires additional npm deps).
    """

    npm_repositories()
    _private_npm_repositories()

    if enable_prisma:
        prisma_setup()
