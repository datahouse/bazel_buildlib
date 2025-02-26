"""Prisma extension."""

load("//private/prisma:engines_version.bzl", "get_prisma_engines_version")
load("//private/prisma:repositories.bzl", "prisma_setup")

def _fail_repository_impl(ctx):
    ctx.template(
        "BUILD",
        Label("//private/prisma:prisma_fail.BUILD"),
    )

_fail_repository = repository_rule(
    implementation = _fail_repository_impl,
)

def _prisma_impl(module_ctx):
    version = get_prisma_engines_version(module_ctx)
    if version:
        prisma_setup(version = version)
    else:
        # Create the @prisma repository anyways for better error reporting.
        _fail_repository(name = "prisma")

    return module_ctx.extension_metadata(
        root_module_direct_deps = ["prisma"],
        root_module_direct_dev_deps = [],
        # The prisma extension itself is reproducible.
        # (the repositories it generates aren't)
        reproducible = True,
    )

prisma = module_extension(implementation = _prisma_impl)
