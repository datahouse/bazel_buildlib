"""Datahouse buildib setup stage 0."""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("//private/docker:ibazel_info.bzl", "ibazel_info")
load("//private/prisma:repositories.bzl", "prisma_host_constraints")

visibility("public")

def dh_buildlib_setup0():
    """Datahouse buildib setup stage 0."""

    http_archive(
        name = "bazel_skylib",
        sha256 = "cd55a062e763b9349921f0f5db8c3933288dc8ba4f76dd9416aac68acee3cb94",
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/bazel-skylib/releases/download/1.5.0/bazel-skylib-1.5.0.tar.gz",
            "https://github.com/bazelbuild/bazel-skylib/releases/download/1.5.0/bazel-skylib-1.5.0.tar.gz",
        ],
    )

    http_archive(
        name = "aspect_bazel_lib",
        sha256 = "bda4a69fa50411b5feef473b423719d88992514d259dadba7d8218a1d02c7883",
        strip_prefix = "bazel-lib-2.3.0",
        url = "https://github.com/aspect-build/bazel-lib/releases/download/v2.3.0/bazel-lib-v2.3.0.tar.gz",
    )

    http_archive(
        name = "rules_nodejs",
        sha256 = "f36e4a4747210331767033dc30728ae3df0856e88ecfdc48a0077ba874db16c3",
        strip_prefix = "rules_nodejs-6.0.3",
        url = "https://github.com/bazelbuild/rules_nodejs/releases/download/v6.0.3/rules_nodejs-v6.0.3.tar.gz",
    )

    http_archive(
        name = "aspect_rules_js",
        sha256 = "0fd06280b6b4982e2fd94be383ac35533ac756ddf34271e1344af0a7ebaafa89",
        strip_prefix = "rules_js-1.36.0",
        url = "https://github.com/aspect-build/rules_js/releases/download/v1.36.0/rules_js-v1.36.0.tar.gz",
    )

    http_archive(
        name = "aspect_rules_ts",
        sha256 = "bd3e7b17e677d2b8ba1bac3862f0f238ab16edb3e43fb0f0b9308649ea58a2ad",
        strip_prefix = "rules_ts-2.1.0",
        url = "https://github.com/aspect-build/rules_ts/releases/download/v2.1.0/rules_ts-v2.1.0.tar.gz",
    )

    http_archive(
        name = "aspect_rules_swc",
        sha256 = "8eb9e42ed166f20cacedfdb22d8d5b31156352eac190fc3347db55603745a2d8",
        strip_prefix = "rules_swc-1.1.0",
        url = "https://github.com/aspect-build/rules_swc/releases/download/v1.1.0/rules_swc-v1.1.0.tar.gz",
    )

    http_archive(
        name = "rules_oci",
        sha256 = "58b7a175ee90c12583afeca388523adf6a4e5a0528f330b41c302b91a4d6fc06",
        strip_prefix = "rules_oci-1.6.0",
        url = "https://github.com/bazel-contrib/rules_oci/releases/download/v1.6.0/rules_oci-v1.6.0.tar.gz",
    )

    # Declare dependency on bazel_features (transitive dependency of rules_js) explicitly.
    # Otherwise we'd need an additional setup stage:
    # 0. http_archive("aspect_rules_js")
    # 1. rules_js_dependencies
    # 2. npm_translate_lock (depends on bazel_features)
    # 3. npm_repositories (depends on npm_translate_lock)
    http_archive(
        name = "bazel_features",
        sha256 = "53182a68f172a2af4ad37051f82201e222bc19f7a40825b877da3ff4c922b9e0",
        strip_prefix = "bazel_features-1.3.0",
        url = "https://github.com/bazel-contrib/bazel_features/releases/download/v1.3.0/bazel_features-v1.3.0.tar.gz",
    )

    # Always load prisma constraints (they are not dependent on prisms itself,
    # so it is OK to always load them).
    prisma_host_constraints(name = "prisma_host_constraints")

    ibazel_info(name = "dh_buildlib_private_ibazel_info")
