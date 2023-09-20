"""Override of the built-in @local_config_platform repository.

This is so we can add auto-detection for the host platform for our own platform constraints.

Most of it is adapted from the POC mentioned in https://github.com/bazelbuild/bazel/issues/8766:
https://github.com/fmeum/host_platform/blob/dbe055efc3ecdc7bfae5d7fbf1667f46f8c34b4e/internal/utils.bzl
"""

load("//private/prisma:lib.bzl", "compute_lib_ssl_specific_paths", "get_ssl_version", "parse_distro")

def _local_config_platform_impl(repository_ctx):
    repository_ctx.template(
        "BUILD",
        Label(":local_config_platform.BUILD.bazel"),
        executable = False,
    )

    constraints = (
        _get_host_cpu_constraint(repository_ctx) +
        _get_host_os_constraint(repository_ctx) +
        _get_prisma_constraints(repository_ctx)
    )

    bzl_lines = [
        "HOST_CONSTRAINTS = [",
    ] + [
        "    \"{}\",".format(constraint)
        for constraint in constraints
    ] + [
        "]",
    ]

    repository_ctx.file("constraints.bzl", content = "\n".join(bzl_lines) + "\n", executable = False)

local_config_platform = repository_rule(
    implementation = _local_config_platform_impl,
)

def _get_prisma_constraints(repository_ctx):
    if repository_ctx.os.name != "linux":
        return []

    distro = parse_distro(repository_ctx.read("/etc/os-release"))
    paths = compute_lib_ssl_specific_paths(distro, repository_ctx.os.arch)
    ssl_version = get_ssl_version(repository_ctx, paths)

    return [
        Label("//private/prisma/constraints:linux_{}".format(distro)),
        Label("//private/prisma/constraints:openssl_{}".format(ssl_version)),
    ]

# Copy of bazel's default host platfrom detection.
# Copied (almost) from https://github.com/fmeum/host_platform/blob/dbe055efc3ecdc7bfae5d7fbf1667f46f8c34b4e/internal/utils.bzl

def _get_host_cpu_constraint(repository_ctx):
    cpu = _JAVA_OS_ARCH_TO_CPU.get(repository_ctx.os.arch)
    if not cpu:
        return []
    return [Label("@platforms//cpu:" + cpu)]

def _get_host_os_constraint(repository_ctx):
    host_java_os_name = repository_ctx.os.name
    for java_os_name, os in _JAVA_OS_NAME_TO_OS.items():
        if host_java_os_name.startswith(java_os_name.lower()):
            return [Label("@platforms//os:" + os)]
    return []

# Taken from
# https://cs.opensource.google/bazel/bazel/+/fe7deabfa094e35a63b83e7912efeb8097c71bc8:src/main/java/com/google/devtools/build/lib/util/CPU.java;l=24
_CPU_TO_JAVA_OS_ARCH_VALUES = {
    "aarch64": ["aarch64"],
    "arm": ["arm", "armv7l"],
    "mips64": ["mips64el", "mips64"],
    "ppc": ["ppc", "ppc64", "ppc64le"],
    "riscv64": ["riscv64"],
    "s390x": ["s390x", "s390"],
    "x86_32": ["i386", "i486", "i586", "i686", "i786", "x86"],
    "x86_64": ["amd64", "x86_64", "x64"],
}

_JAVA_OS_ARCH_TO_CPU = {
    os_arch: cpu
    for cpu, os_arch_values in _CPU_TO_JAVA_OS_ARCH_VALUES.items()
    for os_arch in os_arch_values
}

# Taken from
# https://cs.opensource.google/bazel/bazel/+/fe7deabfa094e35a63b83e7912efeb8097c71bc8:src/main/java/com/google/devtools/build/lib/util/OS.java;l=22
_JAVA_OS_NAME_TO_OS = {
    "FreeBSD": "freebsd",
    "Linux": "linux",
    "Mac OS X": "osx",
    "OpenBSD": "openbsd",
    "Windows": "windows",
}
