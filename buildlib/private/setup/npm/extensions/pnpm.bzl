"""Custom pnpm extension that forces `LATEST_PNPM_VERSION`.

We do not use the rules_js extension since changing the pnpm
version from within buildlib will generate warnings.

Further, it does not allow non-root modules to change the repository name (which
would allow us to use a buildlib private repository, avoiding the warning).
"""

load("@aspect_rules_js//npm:repositories.bzl", "LATEST_PNPM_VERSION", "pnpm_repository")

def _pnpm_extension_impl(module_ctx):
    pnpm_repository(
        name = "pnpm",
        pnpm_version = LATEST_PNPM_VERSION,
    )

    return module_ctx.extension_metadata(
        root_module_direct_deps = ["pnpm"],
        root_module_direct_dev_deps = [],
        reproducible = True,
    )

pnpm = module_extension(
    implementation = _pnpm_extension_impl,
)
