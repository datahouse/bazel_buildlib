"""Prisma extension."""

load("//private/prisma:constants.bzl", "BINARY_TYPES", "PLATFORMS")
load("//private/prisma:lib.bzl", "get_binary_name", "get_download_url")

def _fail_repository_impl(ctx):
    ctx.template(
        "BUILD",
        Label("//private/prisma:prisma_fail.BUILD"),
    )

_fail_repository = repository_rule(
    implementation = _fail_repository_impl,
)

def _prisma_engines_store_repository_impl(ctx):
    platform = ctx.attr.platform
    version = ctx.attr.version

    for binary_type in BINARY_TYPES:
        binary_name = get_binary_name(binary_type, platform)

        ctx.download(
            url = get_download_url(version, platform, binary_type),
            integrity = ctx.attr.integrity[binary_type],
            output = binary_name + ".gz",
        )

    ctx.template(
        "BUILD",
        Label("//private/prisma:engines_store.BUILD.tpl"),
        substitutions = {
            "{PLATFORM}": platform,
        },
        executable = False,
    )

_prisma_engines_store_repository = repository_rule(
    implementation = _prisma_engines_store_repository_impl,
    attrs = {
        "integrity": attr.string_dict(
            doc = "Map from binary_type to integrity",
            mandatory = True,
        ),
        "platform": attr.string(
            values = PLATFORMS.keys(),
            mandatory = True,
        ),
        "version": attr.string(),
    },
)

def _prisma_repository_impl(ctx):
    ctx.template(
        "BUILD",
        Label("//private/prisma:prisma_repo.BUILD"),
    )

_prisma_repository = repository_rule(
    implementation = _prisma_repository_impl,
)

def _get_integrity(module_ctx, version, platform, binary_type):
    url = get_download_url(version, platform, binary_type)
    download_result = module_ctx.download(
        url = url,
        # We need to write somewhere, but only care about the integrity result.
        output = "unused",
    )
    return download_result.integrity

def _prisma_impl(module_ctx):
    # Hardcoding the label is a bit ugly here.
    # The alternative is introducing an extension tag which seems like overkill.
    version = module_ctx.read(Label("@prisma_engines_version//:version.txt"))
    if not version:
        # Create the @prisma repository anyways for better error reporting.
        _fail_repository(name = "prisma")
        return module_ctx.extension_metadata(
            root_module_direct_deps = ["prisma"],
            root_module_direct_dev_deps = [],
            reproducible = True,
        )

    for platform in PLATFORMS.keys():
        # Fetch integrity in extension, so that the repository has an integrity value.
        # This allows us to use the bzlmod lockfile to track integrity values for
        # the prisma engines.
        integrity = {
            binary_type: _get_integrity(module_ctx, version, platform, binary_type)
            for binary_type in BINARY_TYPES
        }

        _prisma_engines_store_repository(
            name = "prisma_engines_" + platform,
            platform = platform,
            version = version,
            integrity = integrity,
        )

    _prisma_repository(
        name = "prisma",
    )

    return module_ctx.extension_metadata(
        root_module_direct_deps = ["prisma"],
        root_module_direct_dev_deps = [],
        reproducible = False,
    )

prisma = module_extension(implementation = _prisma_impl)
