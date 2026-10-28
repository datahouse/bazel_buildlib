"""Prisma extension."""

load(":constants.bzl", "BINARY_TYPES", "PLATFORMS", "SCHEMA_ENGINE_BINARY")
load(":lib.bzl", "get_binary_name", "get_download_url")

def _fail_repository_impl(ctx):
    ctx.template(
        "BUILD",
        Label("//private/prisma:prisma_fail.BUILD"),
    )

    return ctx.repo_metadata(reproducible = True)

_fail_repository = repository_rule(
    implementation = _fail_repository_impl,
)

def _prisma_engines_store_repository_impl(ctx):
    platform = ctx.attr.platform
    version = ctx.attr.version

    for binary_type, integrity in ctx.attr.integrity.items():
        binary_name = get_binary_name(binary_type, platform)

        ctx.download(
            url = get_download_url(version, platform, binary_type),
            integrity = integrity,
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

    return ctx.repo_metadata(reproducible = True)

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

    ctx.file(
        "version.bzl",
        content = "PRISMA7_OR_ABOVE = {}\n".format(ctx.attr.prisma7_or_above),
        executable = False,
    )

    return ctx.repo_metadata(reproducible = True)

_prisma_repository = repository_rule(
    implementation = _prisma_repository_impl,
    attrs = {
        "prisma7_or_above": attr.bool(),
    },
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
    version_info = json.decode(module_ctx.read(Label("@prisma_version_info//:info.json")))
    if version_info == None:
        # Prisma is not installed.
        # Create the @prisma repository anyways for better error reporting.
        _fail_repository(name = "prisma")
        return module_ctx.extension_metadata(
            root_module_direct_deps = ["prisma"],
            root_module_direct_dev_deps = [],
            reproducible = True,
        )

    engines_version = version_info["engines"]
    prisma7_or_above = version_info["prisma7_or_above"]

    binary_types = [SCHEMA_ENGINE_BINARY] if prisma7_or_above else BINARY_TYPES

    new_facts = {}

    for platform in PLATFORMS.keys():
        integrity_for_repo = {}

        for binary_type in binary_types:
            fact_key = "integrity/{}/{}/{}".format(engines_version, platform, binary_type)
            integrity_for_bin = module_ctx.facts.get(fact_key) or _get_integrity(module_ctx, engines_version, platform, binary_type)
            integrity_for_repo[binary_type] = integrity_for_bin
            new_facts[fact_key] = integrity_for_bin

        _prisma_engines_store_repository(
            name = "prisma_engines_" + platform,
            platform = platform,
            version = engines_version,
            integrity = integrity_for_repo,
        )

    _prisma_repository(
        name = "prisma",
        prisma7_or_above = prisma7_or_above,
    )

    return module_ctx.extension_metadata(
        root_module_direct_deps = ["prisma"],
        root_module_direct_dev_deps = [],
        reproducible = True,
        facts = new_facts,
    )

prisma = module_extension(implementation = _prisma_impl)
