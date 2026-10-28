"""Repository rule for prisma repositories."""

load(":lib.bzl", "compute_lib_ssl_specific_paths", "get_ssl_version", "parse_distro")

def _get_prisma_constraints(ctx):
    if ctx.os.name != "linux":
        return []

    distro = parse_distro(ctx.read("/etc/os-release", watch = "yes"))
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

    return ctx.repo_metadata(reproducible = True)

prisma_host_constraints = repository_rule(
    implementation = _prisma_host_constraints_impl,
)
