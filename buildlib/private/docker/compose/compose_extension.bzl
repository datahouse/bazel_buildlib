"""Module extension for docker compose"""

load(":compose_repository.bzl", "compose_repository")
load(":platforms.bzl", "ARCH_TO_CONSTRAINT", "OS_TO_CONSTRAINT")

def _parse_checksums(text):
    if not text:
        fail("Downloaded checksums file is empty")

    checksums = {}
    for line in text.splitlines():
        line = line.strip()
        if not line:
            continue

        parts = line.split(" *")
        if len(parts) != 2:
            fail("\n".join([
                """Downloaded checksums file contains unexpected structure""",
                """Expected line format "<sha245> *file_name". Got "{}""".format(line),
            ]))

        sha, name = parts
        if name in checksums:
            fail("Downloaded checksums file contains duplicate file name: {}".format(name))

        checksums[name] = sha
    return checksums

def _create_repository(os, arch, version, checksums):
    file_name = "docker-compose-{}-{}{}".format(os, arch, ".exe" if os == "windows" else "")
    repository_name = "dc_{}_{}".format(os, arch)
    checksum = checksums[file_name]
    url = "https://github.com/docker/compose/releases/download/v{}/{}".format(version, file_name)
    compose_repository(
        name = repository_name,
        url = url,
        sha256 = checksum,
    )
    return repository_name

def _get_version_from_tag(modules):
    if len(modules) != 1:
        return fail("Expected exactly one module, got {}".format(modules))

    download = modules[0].tags.download
    if len(download) != 1:
        return fail("Expected exactly one download tag, got: {}".format(download))

    return download[0].version

def _compose_bin_extension_impl(module_ctx):
    version = _get_version_from_tag(module_ctx.modules)
    checksums_file_url = "https://github.com/docker/compose/releases/download/v{}/checksums.txt".format(version)
    module_ctx.download(
        url = [checksums_file_url],
        output = "checksums.txt",
    )
    checksums = _parse_checksums(module_ctx.read("checksums.txt"))

    repos = [
        _create_repository(os, arch, version, checksums)
        for os in OS_TO_CONSTRAINT.keys()
        for arch in ARCH_TO_CONSTRAINT.keys()
    ]

    return module_ctx.extension_metadata(
        reproducible = False,
        root_module_direct_deps = repos,
        root_module_direct_dev_deps = [],
    )

_download = tag_class(
    attrs = {"version": attr.string(mandatory = True)},
)

compose_bin_extension = module_extension(
    implementation = _compose_bin_extension_impl,
    tag_classes = {"download": _download},
)
