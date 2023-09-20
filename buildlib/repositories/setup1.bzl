"""Datahouse buildib setup stage 1."""

load("@aspect_rules_js//npm:npm_import.bzl", "npm_translate_lock")
load("@aspect_rules_swc//swc:dependencies.bzl", "rules_swc_dependencies")
load("@aspect_rules_swc//swc:repositories.bzl", "LATEST_SWC_VERSION", "swc_register_toolchains")
load("@aspect_rules_ts//ts:repositories.bzl", "rules_ts_dependencies")
load("@bazel_skylib//lib:dicts.bzl", "dicts")
load("@io_bazel_rules_docker//repositories:repositories.bzl", container_repositories = "repositories")
load("@rules_nodejs//nodejs:repositories.bzl", "nodejs_register_toolchains")

visibility("public")

def dh_buildlib_setup1(bins = {}):
    """Datahouse buildib setup stage 1.

    Args:
      bins: Additional bins passed to npm_translate_lock for the npm repository.
        Keys provided here take precedence over the default ones.
    """

    nodejs_register_toolchains(
        use_nvmrc = "//:.nvmrc",
    )

    rules_ts_dependencies(
        ts_version_from = "@npm//:typescript/resolved.json",
    )

    rules_swc_dependencies()

    swc_register_toolchains(
        name = "swc",
        swc_version = LATEST_SWC_VERSION,
    )

    container_repositories()

    # Main npm repository comes from user workspace.
    npm_translate_lock(
        name = "npm",
        npmrc = "//:.npmrc",
        pnpm_lock = "//:pnpm-lock.yaml",
        verify_node_modules_ignored = "//:.bazelignore",
        lifecycle_hooks = {
            # disable, unnecesary (and non-hermetic) usability bootstrapping
            # https://github.com/prisma/prisma/blob/e0273500754e27f2b37ad709dde7dd73db40bd2a/packages/client/package.json#L48
            # https://github.com/prisma/prisma/blob/e0273500754e27f2b37ad709dde7dd73db40bd2a/packages/client/scripts/postinstall.js#L52-L63
            "@prisma/client": [],
            # disable, downloads prisma engines:
            # https://github.com/prisma/prisma/blob/e0273500754e27f2b37ad709dde7dd73db40bd2a/packages/engines/package.json#L32
            # https://github.com/prisma/prisma/blob/e0273500754e27f2b37ad709dde7dd73db40bd2a/packages/engines/src/scripts/postinstall.ts
            "@prisma/engines": [],
        },
        # sandbox all lifecycle hooks (the default is no-sandbox, but we'd rather have safety over speed).
        lifecycle_hooks_execution_requirements = {"*": []},
        # Well-known bins.
        #
        # TODO: Remove once npm_translate_lock doesn't require the `bins`
        # argument anymore
        # See https://github.com/pnpm/pnpm/issues/5131
        bins = dicts.add(
            # Defaults.
            {
                "prisma": {
                    "prisma": "./build/index.js",
                },
                "typegraphql-prisma": {
                    "typegraphql-prisma": "./lib/generator.js",
                },
                "vite": {
                    "vite": "./bin/vite.js",
                },
            },
            # User provided bins.
            bins,
        ),
    )

    # dh_buildlib_private_npm repository always comes from the buildlib workspace.
    npm_translate_lock(
        name = "dh_buildlib_private_npm",
        npmrc = Label("//:.npmrc"),
        pnpm_lock = Label("//private:pnpm-lock.yaml"),
        verify_node_modules_ignored = Label("//:.bazelignore"),
        # sandbox all lifecycle hooks (the default is no-sandbox, but we'd rather have safety over speed).
        lifecycle_hooks_execution_requirements = {"*": []},
    )
