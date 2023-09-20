"""Rules for language agnostic tooling

Typically they appear in the repository root. They make sure the configs are
in-line with Datahouse standards and consistent with each other.

Also see [examples/BUILD.bazel](../../examples/BUILD.bazel).
"""

load("//private/bazelrc:bazelrc.bzl", _bazelrc = "bazelrc")
load("//private/renovate:renovate.bzl", _renovate_config = "renovate_config")

bazelrc = _bazelrc
renovate_config = _renovate_config
