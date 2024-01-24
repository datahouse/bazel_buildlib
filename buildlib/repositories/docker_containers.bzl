"""DH specific repository rules relating to docker containers."""

load("@rules_oci//oci:pull.bzl", "oci_pull")

visibility("public")

def container_pull(
        name,
        registry,
        repository,
        digest,
        tag,  # @unused
        os,  # @unused,
        architecture):  # @unused
    """Pulls a docker image from a docker registry.

    This is a repository rule, you can only use it in the WORKSPACE file.

    Example: [`example/WORKSPACE`](../../examples/WORKSPACE#:~:text=name%20%3D%20%22nginx_image%22%2C).

    This calls
    [oci_pull](https://github.com/bazel-contrib/rules_oci/blob/main/docs/pull.md)
    under the hood.

    Args:
      name: name of the repository
      registry: registry to pull from (e.g. `index.docker.io`)
      repository: repository to pull (e.g. `nginx`)
      tag: tag to pull (e.g. `2.3.4`).
          This is for documentation purposes / renovate only.
          The actual image is determined via the digest.
      digest: digest to pull (e.g. `sha256:abcdef...`)
      os: Operating system to pull for (typically `linux`).
          This is for documentation purposes / renovate only.
          The actual image is determined via the digest.
      architecture: Architecture to pull for (typically `amd64`).
          This is for documentation purposes / renovate only.
          The actual image is determined via the digest.
    """

    # The registry / repository arguments are somewhat historical
    # (from rules_docker). When migrating to rules_oci (#146), we left them in
    # this form to not unnecessarily require downstream changes (and they make
    # the mirror config easier).

    if registry == "index.docker.io":
        registry = "docker.datarepo.ch"

        if not "/" in repository:
            repository = "library/" + repository

        repository = "docker-hub-cache/" + repository

    oci_pull(
        name = name,
        digest = digest,
        image = "{}/{}".format(registry, repository),
    )
