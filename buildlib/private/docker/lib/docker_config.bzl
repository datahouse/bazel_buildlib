"""Repository rule to capture DOCKER_HOST environment variable."""

_DEFAULT_DOCKER_HOST = "unix:///var/run/docker.sock"

_build_file_content = """
load("@bazel_lib//:bzl_library.bzl", "bzl_library")

bzl_library(
  name = "docker_config",
  srcs = ["docker_config.bzl"],
  visibility = ["//visibility:public"],
)
"""

def _docker_config_impl(repo_ctx):
    docker_host = repo_ctx.getenv("DOCKER_HOST", _DEFAULT_DOCKER_HOST)
    allow_non_localhost_bind = (
        # User explicitly allowed.
        repo_ctx.getenv("DH_BUILDLIB_PERMIT_NON_LOCALHOST_BIND") != None or
        # Drone docker pipelines isolate from the outside world.
        repo_ctx.getenv("DRONE_STAGE_TYPE") == "docker"
    )

    lines = [
        "DOCKER_HOST = %s\n" % json.encode(docker_host),
        "allow_non_localhost_bind = %s\n" % allow_non_localhost_bind,
    ]

    repo_ctx.file("BUILD.bazel", _build_file_content)
    repo_ctx.file("docker_config.bzl", "".join(lines))
    return repo_ctx.repo_metadata(reproducible = True)

docker_config = repository_rule(
    implementation = _docker_config_impl,
    doc = "Captures relevant environment variables for using the Docker subsystem.",
)
