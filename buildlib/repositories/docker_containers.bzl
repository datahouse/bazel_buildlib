"""DH specific repository rules relating to docker containers."""

load("@io_bazel_rules_docker//container:container.bzl", _container_pull = "container_pull")

visibility("public")

def container_pull(name, registry, repository, tag, digest, os, architecture):
    """Shim around rules_docker container_pull to use our own mirror.

    See rules_docker for documentation:
    https://github.com/bazelbuild/rules_docker/blob/master/docs/container.md#container_pull

    Args:
      name: name of the repository
      registry: registry to pull from (e.g. `index.docker.io`)
      repository: repository to pull (e.g. `nginx`)
      tag: tag to pull (e.g. `2.3.4`).
          This is for documentation purposes / renovate only.
          The actual image is determined via the digest.
      digest: digest to pull (e.g. `sha256:abcdef...`)
      os: Operating system to pull for (typically `linux`).
      architecture: Architecture to pull for (typically `amd64`).
    """

    if registry == "index.docker.io":
        registry = "docker.datarepo.ch"

        if not "/" in repository:
            repository = "library/" + repository

        repository = "docker-hub-cache/" + repository

    _container_pull(
        name = name,
        registry = registry,
        repository = repository,
        tag = tag,
        digest = digest,
        os = os,
        architecture = architecture,
    )
