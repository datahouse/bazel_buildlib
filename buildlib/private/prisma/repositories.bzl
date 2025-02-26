"""Repository rule for prisma repositories."""

load("//private/prisma:constants.bzl", "BINARY_TYPES", "PLATFORMS")
load("//private/prisma:lib.bzl", "compute_lib_ssl_specific_paths", "get_binary_name", "get_download_url", "get_ssl_version", "parse_distro")
load(":engines_version.bzl", "get_prisma_engines_version")

def _prisma_engines_store_repository_impl(ctx):
    platform = ctx.attr.platform
    version = ctx.attr.version

    if not version:
        version = get_prisma_engines_version(ctx)

    if version == None:
        fail("couldn't find prisma in devDependencies")

    for binary_type in BINARY_TYPES:
        binary_name = get_binary_name(binary_type, platform)

        ctx.download(
            url = get_download_url(version, platform, binary_type),
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

def prisma_setup(version = None):
    """Create repositories for prisma engines (for use in prisma rules)."""

    for platform in PLATFORMS.keys():
        _prisma_engines_store_repository(
            name = "prisma_engines_" + platform,
            platform = platform,
            version = version,
        )

    _prisma_repository(
        name = "prisma",
    )

def _get_prisma_constraints(ctx):
    if ctx.os.name != "linux":
        return []

    distro = parse_distro(ctx.read("/etc/os-release"))
    paths = compute_lib_ssl_specific_paths(distro, ctx.os.arch)
    ssl_version = get_ssl_version(ctx, paths)

    return [
        Label("//prisma/linux:{}".format(distro)),
        Label("//prisma/openssl:{}".format(ssl_version)),
    ]

def _prisma_host_constraints_impl(ctx):
    bzl_lines = [
        "PRISMA_HOST_CONSTRAINTS = [",
    ] + [
        "    \"{}\",".format(constraint)
        for constraint in _get_prisma_constraints(ctx)
    ] + [
        "]",
    ]

    ctx.file("constraints.bzl", content = "\n".join(bzl_lines) + "\n", executable = False)
    ctx.file("BUILD", content = """exports_files("constraints.bzl")""", executable = False)

prisma_host_constraints = repository_rule(
    implementation = _prisma_host_constraints_impl,
)
