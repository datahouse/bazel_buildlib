"""Repository rule for prisma repositories."""

load("//private/prisma:constants.bzl", "BINARY_TYPES", "PLATFORMS")
load("//private/prisma:lib.bzl", "compute_lib_ssl_specific_paths", "get_binary_name", "get_download_url", "get_ssl_version", "parse_distro")

def _get_primsa_engines_version(ctx):
    """Extract the engine version (commit SHA) from the @prisma/engines-version package."""

    resolved = json.decode(ctx.read(ctx.attr.resolved_json))

    # Version SHA is in build metadata:
    # 4.12.0-34.b36012d6e9bd4f7ff6b13fa02556b753d8bc9094
    raw_version = resolved["version"]
    version = raw_version.split(".")[-1]

    if len(version) != 40:
        fail("expected 40 char SHA for prisma engines version, got %s" % raw_version)

    return version

def _prisma_engines_store_repository_impl(ctx):
    platform = ctx.attr.platform
    version = _get_primsa_engines_version(ctx)

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
        "resolved_json": attr.label(
            allow_single_file = [".json"],
        ),
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

def prisma_setup():
    """Create repositories for prisma engines (for use in prisma rules)."""

    for platform in PLATFORMS.keys():
        _prisma_engines_store_repository(
            name = "prisma_engines_" + platform,
            platform = platform,
            resolved_json = "@npm//:@prisma/engines-version/resolved.json",
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
