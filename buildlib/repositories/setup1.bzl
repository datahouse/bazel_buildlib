"""Datahouse buildib setup stage 1."""

load("@aspect_bazel_lib//lib:repositories.bzl", "aspect_bazel_lib_dependencies", "aspect_bazel_lib_register_toolchains")
load("@aspect_rules_js//npm:repositories.bzl", "LATEST_PNPM_VERSION", "npm_translate_lock")
load("@aspect_rules_swc//swc:dependencies.bzl", "rules_swc_dependencies")
load("@aspect_rules_swc//swc:repositories.bzl", "LATEST_SWC_VERSION", "swc_register_toolchains")
load("@aspect_rules_ts//ts:repositories.bzl", "rules_ts_dependencies")
load("@buildifier_prebuilt//:defs.bzl", "buildifier_prebuilt_register_toolchains")
load("@platforms//host:extension.bzl", "host_platform_repo")
load("@rules_nodejs//nodejs:repositories.bzl", "nodejs_register_toolchains")
load("@rules_oci//oci:dependencies.bzl", "rules_oci_dependencies")
load("@rules_oci//oci:repositories.bzl", "oci_register_toolchains")
load("//private/prisma:repositories.bzl", "prisma_host_constraints")

visibility("public")

def dh_buildlib_setup1(bins = {}):
    """Datahouse buildib setup stage 1.

    Args:
      bins: Additional bins passed to npm_translate_lock for the npm repository.
        Keys provided here take precedence over the default ones.
    """

    host_platform_repo(name = "host_platform")

    nodejs_register_toolchains(
        node_version_from_nvmrc = "//:.nvmrc",
    )

    rules_ts_dependencies(
        ts_version_from = "@npm//:typescript/resolved.json",
    )

    rules_ts_dependencies(
        name = "dh_buildlib_private_typescript",
        ts_version_from = "@dh_buildlib_private_npm//:typescript/resolved.json",
    )

    rules_swc_dependencies()

    swc_register_toolchains(
        name = "swc",
        swc_version = LATEST_SWC_VERSION,
    )

    aspect_bazel_lib_dependencies()
    aspect_bazel_lib_register_toolchains()

    rules_oci_dependencies()

    oci_register_toolchains(
        name = "oci",
    )

    npm_translate_lock(
        name = "npm",
        npmrc = "//:.npmrc",
        pnpm_lock = "//:pnpm-lock.yaml",
        verify_node_modules_ignored = "//:.bazelignore",
        lifecycle_hooks_no_sandbox = False,  # safety over speed.
        pnpm_version = LATEST_PNPM_VERSION,
        bins = bins,
    )

    # dh_buildlib_private_npm repository always comes from the buildlib workspace.
    npm_translate_lock(
        name = "dh_buildlib_private_npm",
        npmrc = Label("//:.npmrc"),
        pnpm_lock = Label("//:pnpm-lock.yaml"),
        verify_node_modules_ignored = Label("//:.bazelignore"),
        lifecycle_hooks_no_sandbox = False,  # safety over speed.
        pnpm_version = LATEST_PNPM_VERSION,
    )

    buildifier_prebuilt_register_toolchains()

    # Always load prisma constraints (they are not dependent on prisma itself,
    # so it is OK to always load them).
    prisma_host_constraints(name = "prisma_host_constraints")
