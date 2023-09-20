"""Extract information about pulled docker imags."""

load("@io_bazel_rules_docker//container:providers.bzl", "PullInfo")

def pull_info_dict(target):
    """Converts the data in the PullInfo provider to a dict.

    This is typically used for JSON serialization.

    Args:
      target: The target to read the PullInfo from.

    Returns:
      A dict with the following fields:
        digest: the image digest (e.g. `sha256:<hash>`)
        registry: the image registry (e.g. `docker.datarepo.ch`)
        repository: the image repository (e.g. `project-abc/proxy`)
        reference: the full image reference
          (e.g. `docker.datarepo.ch/project-abc/proxy@sha256:<hash>`)
    """

    info = target[PullInfo]

    registry = info.base_image_registry
    repository = info.base_image_repository
    digest = info.base_image_digest
    reference = "{}/{}@{}".format(registry, repository, digest)

    return {
        "digest": digest,
        "reference": reference,
        "registry": registry,
        "repository": repository,
    }

def _docker_pull_info_impl(ctx):
    ctx.actions.write(ctx.outputs.out, json.encode(pull_info_dict(ctx.attr.image)))

docker_pull_info = rule(
    implementation = _docker_pull_info_impl,
    doc = """Generates a json with info about a pulled image.

Example: [`@examples//prisma/test:postgres_info`](../../examples/prisma/test/BUILD.bazel#:~:text=name%20%3D%20%22postgres_info%22%2C)
    """,
    attrs = {
        "image": attr.label(
            doc = "Image to get info from (must be a container_pull target).",
            providers = [PullInfo],
            mandatory = True,
        ),
        "out": attr.output(
            doc = "json file to write info to.",
            mandatory = True,
        ),
    },
)
