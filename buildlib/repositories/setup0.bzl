"""Datahouse buildib setup stage 0."""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("//private/docker:ibazel_info.bzl", "ibazel_info")

visibility("public")

# False positive due to buildifier_repos()
# buildifier: disable=unnamed-macro
def dh_buildlib_setup0():
    """Datahouse buildib setup stage 0."""

    http_archive(
        name = "platforms",
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/platforms/releases/download/0.0.11/platforms-0.0.11.tar.gz",
            "https://github.com/bazelbuild/platforms/releases/download/0.0.11/platforms-0.0.11.tar.gz",
        ],
        sha256 = "29742e87275809b5e598dc2f04d86960cc7a55b3067d97221c9abbc9926bff0f",
    )

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
        sha256 = "57a777c5d4d0b79ad675995ee20fc1d6d2514a1ef3000d98f5c70cf0c09458a3",
        strip_prefix = "bazel-lib-2.13.0",
        url = "https://github.com/aspect-build/bazel-lib/releases/download/v2.13.0/bazel-lib-v2.13.0.tar.gz",
    )

    http_archive(
        name = "rules_nodejs",
        sha256 = "732aa2aeef9ba629cd7fa1cb30da07e6b696ed78706b08d84d5d8601982f38b1",
        strip_prefix = "rules_nodejs-6.3.3",
        url = "https://github.com/bazelbuild/rules_nodejs/releases/download/v6.3.3/rules_nodejs-v6.3.3.tar.gz",
    )

    http_archive(
        name = "aspect_rules_js",
        sha256 = "875b8d01af629dbf626eddc5cf239c9f0da20330f4d99ad956afc961096448dd",
        strip_prefix = "rules_js-2.1.3",
        url = "https://github.com/aspect-build/rules_js/releases/download/v2.1.3/rules_js-v2.1.3.tar.gz",
    )

    http_archive(
        name = "aspect_rules_ts",
        sha256 = "4263532b2fb4d16f309d80e3597191a1cb2fb69c19e95d91711bd6b97874705e",
        strip_prefix = "rules_ts-3.5.0",
        url = "https://github.com/aspect-build/rules_ts/releases/download/v3.5.0/rules_ts-v3.5.0.tar.gz",
    )

    http_archive(
        name = "aspect_rules_swc",
        sha256 = "d9ed410eb6a5c605345d872f0c4c50138bda3c572db2aed1796cf397fa361986",
        strip_prefix = "rules_swc-2.3.0",
        url = "https://github.com/aspect-build/rules_swc/releases/download/v2.3.0/rules_swc-v2.3.0.tar.gz",
    )

    http_archive(
        name = "rules_oci",
        sha256 = "8676144f96dd63294333906b26dea2388f61cadaf1dea59a225e7dbc52cc72fa",
        strip_prefix = "rules_oci-2.2.2",
        url = "https://github.com/bazel-contrib/rules_oci/releases/download/v2.2.2/rules_oci-v2.2.2.tar.gz",
    )

    # Declare dependency on bazel_features (transitive dependency of rules_js) explicitly.
    # Otherwise we'd need an additional setup stage:
    # 0. http_archive("aspect_rules_js")
    # 1. rules_js_dependencies
    # 2. npm_translate_lock (depends on bazel_features)
    # 3. npm_repositories (depends on npm_translate_lock)
    http_archive(
        name = "bazel_features",
        sha256 = "4fd9922d464686820ffd8fcefa28ccffa147f7cdc6b6ac0d8b07fde565c65d66",
        strip_prefix = "bazel_features-1.25.0",
        url = "https://github.com/bazel-contrib/bazel_features/releases/download/v1.25.0/bazel_features-v1.25.0.tar.gz",
    )

    http_archive(
        name = "buildifier_prebuilt",
        sha256 = "5dbf72e4f93917edfb91f53958d6289736adb845b2b89dbfb9bfc199a492030c",
        strip_prefix = "buildifier-prebuilt-8.0.1",
        urls = [
            "http://github.com/keith/buildifier-prebuilt/archive/8.0.1.tar.gz",
        ],
    )

    ibazel_info(name = "dh_buildlib_private_ibazel_info")
