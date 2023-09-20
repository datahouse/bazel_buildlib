"""Datahouse buildib setup stage 0."""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("//private/docker:ibazel_info.bzl", "ibazel_info")
load("//private/prisma:local_config_platform.bzl", "local_config_platform")

visibility("public")

def dh_buildlib_setup0():
    """Datahouse buildib setup stage 0."""

    http_archive(
        name = "bazel_skylib",
        sha256 = "66ffd9315665bfaafc96b52278f57c7e2dd09f5ede279ea6d39b2be471e7e3aa",
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/bazel-skylib/releases/download/1.4.2/bazel-skylib-1.4.2.tar.gz",
            "https://github.com/bazelbuild/bazel-skylib/releases/download/1.4.2/bazel-skylib-1.4.2.tar.gz",
        ],
    )

    http_archive(
        name = "aspect_bazel_lib",
        sha256 = "9a51150a25ba13e0301b47bbe731aef537330dcc222dc598ebdfe18d2efe2f33",
        strip_prefix = "bazel-lib-1.34.5",
        url = "https://github.com/aspect-build/bazel-lib/archive/refs/tags/v1.34.5.tar.gz",
    )

    http_archive(
        name = "rules_nodejs",
        sha256 = "5ad078287b5f3069735652e1fc933cb2e2189b15d2c9fc826c889dc466c32a07",
        strip_prefix = "rules_nodejs-6.0.1",
        url = "https://github.com/bazelbuild/rules_nodejs/releases/download/v6.0.1/rules_nodejs-v6.0.1.tar.gz",
    )

    http_archive(
        name = "aspect_rules_js",
        sha256 = "77c4ea46c27f96e4aadcc580cd608369208422cf774988594ae8a01df6642c82",
        strip_prefix = "rules_js-1.32.2",
        url = "https://github.com/aspect-build/rules_js/releases/download/v1.32.2/rules_js-v1.32.2.tar.gz",
    )

    http_archive(
        name = "aspect_rules_ts",
        sha256 = "8aabb2055629a7becae2e77ae828950d3581d7fc3602fe0276e6e039b65092cb",
        strip_prefix = "rules_ts-2.0.0",
        url = "https://github.com/aspect-build/rules_ts/releases/download/v2.0.0/rules_ts-v2.0.0.tar.gz",
    )

    http_archive(
        name = "aspect_rules_swc",
        sha256 = "8eb9e42ed166f20cacedfdb22d8d5b31156352eac190fc3347db55603745a2d8",
        strip_prefix = "rules_swc-1.1.0",
        url = "https://github.com/aspect-build/rules_swc/releases/download/v1.1.0/rules_swc-v1.1.0.tar.gz",
    )

    http_archive(
        name = "io_bazel_rules_docker",
        sha256 = "b1e80761a8a8243d03ebca8845e9cc1ba6c82ce7c5179ce2b295cd36f7e394bf",
        url = "https://github.com/bazelbuild/rules_docker/releases/download/v0.25.0/rules_docker-v0.25.0.tar.gz",
        # Hack: Change the visibility of //contrib:push-all_bzl so we can use it for stardoc.
        patches = [
            Label("//private/docker:public-contrib-bzl.patch"),
        ],
    )

    # Declare dependency on bazel_features (transitive dependency of rules_js) explicitly.
    # Otherwise we'd need an additional setup stage:
    # 0. http_archive("aspect_rules_js")
    # 1. rules_js_dependencies
    # 2. npm_translate_lock (depends on bazel_features)
    # 3. npm_repositories (depends on npm_translate_lock)
    http_archive(
        name = "bazel_features",
        sha256 = "e210faab57643fb6752f0b7f0d120976a299d5da9ed20e20129ee1134a3cfc7c",
        strip_prefix = "bazel_features-1.1.0",
        url = "https://github.com/bazel-contrib/bazel_features/releases/download/v1.1.0/bazel_features-v1.1.0.tar.gz",
    )

    # Override definition of host config.
    #
    # This is so we can inject our own autodetection.
    #
    # See https://github.com/bazelbuild/bazel/issues/8766
    #
    # TODO: Replace with something more standard once it is available.
    local_config_platform(name = "local_config_platform")

    ibazel_info(name = "dh_buildlib_private_ibazel_info")
