"""Datahouse buildib setup stage 0."""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("//private/docker:ibazel_info.bzl", "ibazel_info")
load("//private/format:repositories.bzl", "buildifier_repos")
load("//private/prisma:repositories.bzl", "prisma_host_constraints")

visibility("public")

# False positive due to buildifier_repos()
# buildifier: disable=unnamed-macro
def dh_buildlib_setup0():
    """Datahouse buildib setup stage 0."""

    http_archive(
        name = "bazel_skylib",
        sha256 = "bc283cdfcd526a52c3201279cda4bc298652efa898b10b4db0837dc51652756f",
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/bazel-skylib/releases/download/1.7.1/bazel-skylib-1.7.1.tar.gz",
            "https://github.com/bazelbuild/bazel-skylib/releases/download/1.7.1/bazel-skylib-1.7.1.tar.gz",
        ],
    )

    http_archive(
        name = "aspect_bazel_lib",
        sha256 = "688354ee6beeba7194243d73eb0992b9a12e8edeeeec5b6544f4b531a3112237",
        strip_prefix = "bazel-lib-2.8.1",
        url = "https://github.com/aspect-build/bazel-lib/releases/download/v2.8.1/bazel-lib-v2.8.1.tar.gz",
    )

    http_archive(
        name = "rules_nodejs",
        sha256 = "87c6171c5be7b69538d4695d9ded29ae2626c5ed76a9adeedce37b63c73bef67",
        strip_prefix = "rules_nodejs-6.2.0",
        url = "https://github.com/bazelbuild/rules_nodejs/releases/download/v6.2.0/rules_nodejs-v6.2.0.tar.gz",
    )

    http_archive(
        name = "aspect_rules_js",
        sha256 = "6b7e73c35b97615a09281090da3645d9f03b2a09e8caa791377ad9022c88e2e6",
        strip_prefix = "rules_js-2.0.0",
        url = "https://github.com/aspect-build/rules_js/releases/download/v2.0.0/rules_js-v2.0.0.tar.gz",
    )

    http_archive(
        name = "aspect_rules_ts",
        sha256 = "ee7dcc35faef98f3050df9cf26f2a72ef356cab8ad927efb1c4dc119ac082a19",
        strip_prefix = "rules_ts-3.0.0",
        url = "https://github.com/aspect-build/rules_ts/releases/download/v3.0.0/rules_ts-v3.0.0.tar.gz",
    )

    http_archive(
        name = "aspect_rules_swc",
        sha256 = "d63d7b283249fa942f78d2716ecff3edbdc10104ee1b9a6b9464ece471ef95ea",
        strip_prefix = "rules_swc-2.0.0",
        url = "https://github.com/aspect-build/rules_swc/releases/download/v2.0.0/rules_swc-v2.0.0.tar.gz",
    )

    http_archive(
        name = "rules_oci",
        sha256 = "46ce9edcff4d3d7b3a550774b82396c0fa619cc9ce9da00c1b09a08b45ea5a14",
        strip_prefix = "rules_oci-1.8.0",
        url = "https://github.com/bazel-contrib/rules_oci/releases/download/v1.8.0/rules_oci-v1.8.0.tar.gz",
    )

    # Declare dependency on bazel_features (transitive dependency of rules_js) explicitly.
    # Otherwise we'd need an additional setup stage:
    # 0. http_archive("aspect_rules_js")
    # 1. rules_js_dependencies
    # 2. npm_translate_lock (depends on bazel_features)
    # 3. npm_repositories (depends on npm_translate_lock)
    http_archive(
        name = "bazel_features",
        sha256 = "ba1282c1aa1d1fffdcf994ab32131d7c7551a9bc960fbf05f42d55a1b930cbfb",
        strip_prefix = "bazel_features-1.15.0",
        url = "https://github.com/bazel-contrib/bazel_features/releases/download/v1.15.0/bazel_features-v1.15.0.tar.gz",
    )

    # Always load prisma constraints (they are not dependent on prisms itself,
    # so it is OK to always load them).
    prisma_host_constraints(name = "prisma_host_constraints")

    ibazel_info(name = "dh_buildlib_private_ibazel_info")

    buildifier_repos()
