"""Repository rules for the github_bin extension"""

def _bin_repository_impl(ctx):
    ctx.download(
        url = [ctx.attr.url],
        output = "bin",
        sha256 = ctx.attr.sha256,
        executable = True,
    )

    # Add a copy_file so the target is in the bazel bin dir (to make rules_js happy).
    # Note: We do not use copy_to_bin, because it does not support symlinks.
    lines = [
        """load("@bazel_lib//lib:copy_file.bzl", "copy_file")""",
        """copy_file(""",
        """  name = "bin_copy",""",
        """  src = "bin",""",
        """  out = "copied_bin",""",
        """  is_executable = True,""",
        """  allow_symlink = True,""",
        """  visibility = ["//visibility:public"],""",
        """)""",
    ]

    ctx.file("BUILD", "\n".join(lines))

    return ctx.repo_metadata(reproducible = True)

bin_repository = repository_rule(
    doc = "Repository rule to download a (standalone) binary.",
    implementation = _bin_repository_impl,
    attrs = {
        "sha256": attr.string(mandatory = True),
        "url": attr.string(mandatory = True),
    },
)

def _bin_select_repository_impl(ctx):
    lines = []

    for os, os_constraint in ctx.attr.os.items():
        for arch, arch_constraint in ctx.attr.arch.items():
            lines.extend([
                """config_setting(""",
                """  name = "config_{}_{}",""".format(os, arch),
                """  constraint_values = [""",
                """     "{}",""".format(os_constraint),
                """     "{}",""".format(arch_constraint),
                """  ],""",
                """)""",
            ])

    lines.extend([
        """alias(""",
        """  name = "{}",""".format(ctx.original_name),
        """  actual = select({""",
    ] + [
        """":config_{os}_{arch}": "@{name}_{os}_{arch}//:bin_copy",""".format(name = ctx.original_name, os = os, arch = arch)
        for os in ctx.attr.os.keys()
        for arch in ctx.attr.arch.keys()
    ] + [
        """  },""",
        """  no_match_error = "{}: unsupported platform",""".format(ctx.original_name),
        """  ),""",
        """  visibility = ["//visibility:public"],""",
        """)""",
    ])

    ctx.file("BUILD", "\n".join(lines))

    return ctx.repo_metadata(reproducible = True)

bin_select_repository = repository_rule(
    doc = "Repository rule to select the appropriate bin repository.",
    implementation = _bin_select_repository_impl,
    attrs = {
        "arch": attr.string_keyed_label_dict(),
        "os": attr.string_keyed_label_dict(),
    },
)
