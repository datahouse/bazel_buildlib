"""Module extension for GitHub standalone binaries"""

load(":github_bin_repository.bzl", "bin_repository", "bin_select_repository")

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

def _release_download_url(tag, file_name):
    return "https://github.com/{repo}/releases/download/{tag}/{file_name}".format(
        repo = tag.github_repo,
        tag = tag.git_tag,  # releases are identified by their tag, not their name.
        file_name = file_name,
    )

def _facts_key(tag):
    return "{}/{}".format(tag.github_repo, tag.git_tag)

def _fetch_checksums(module_ctx, tag):
    checksums_file_url = _release_download_url(tag, tag.filename_checksums)

    file_name = "{}_checksums.txt".format(tag.name)

    module_ctx.download(
        url = [checksums_file_url],
        output = file_name,
    )

    return _parse_checksums(module_ctx.read(file_name))

def _create_repository(tag, os, arch, checksums):
    file_name = tag.filename_pattern.format(os = os, arch = arch)
    bin_repository(
        name = "{}_{}_{}".format(tag.name, os, arch),
        url = _release_download_url(tag, file_name),
        sha256 = checksums[file_name],
    )

def _github_bin_extension_impl(module_ctx):
    repos = []
    facts = {}

    for module in module_ctx.modules:
        for tag in module.tags.download:
            key = _facts_key(tag)
            checksums = (
                facts.get(key) or
                module_ctx.facts.get(key) or
                _fetch_checksums(module_ctx, tag)
            )

            for os in tag.supported_os.keys():
                for arch in tag.supported_arch.keys():
                    _create_repository(tag, os, arch, checksums)

            bin_select_repository(
                name = tag.name,
                arch = tag.supported_arch,
                os = tag.supported_os,
            )

            facts[key] = checksums
            repos.append(tag.name)

    return module_ctx.extension_metadata(
        reproducible = True,
        facts = facts,
        root_module_direct_deps = repos,
        root_module_direct_dev_deps = [],
    )

_download = tag_class(
    attrs = {
        "filename_checksums": attr.string(mandatory = True),
        "filename_pattern": attr.string(mandatory = True),
        "git_tag": attr.string(mandatory = True),
        "github_repo": attr.string(mandatory = True),
        "name": attr.string(mandatory = True),
        "supported_arch": attr.string_keyed_label_dict(mandatory = True),
        "supported_os": attr.string_keyed_label_dict(mandatory = True),
    },
)

github_bin_extension = module_extension(
    implementation = _github_bin_extension_impl,
    tag_classes = {"download": _download},
)
