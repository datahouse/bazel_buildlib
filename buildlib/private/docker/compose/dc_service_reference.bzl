"""Rules to reference docker-compose services."""

load(":providers.bzl", "DcServiceReferenceInfo", "DockerComposeInfo")

def _dc_service_reference_impl(ctx):
    dc_info = ctx.attr.dc[DockerComposeInfo]

    return [
        DcServiceReferenceInfo(
            project = dc_info.project,
            service = ctx.attr.service_name,
            index = ctx.attr.index,
            port = ctx.attr.port,
            compose_label = str(ctx.attr.dc.label),
        ),
    ]

dc_service_reference = rule(
    doc = """Reference to an internal port of a docker service.

Example: [`@examples//dc:db`](../../examples/dc/BUILD.bazel#:~:text=name%20%3D%20%22db%22%2C)
""",
    attrs = {
        "dc": attr.label(
            doc = "Docker compose rule that contains the target service",
            providers = [DockerComposeInfo],
            mandatory = True,
        ),
        "index": attr.int(
            doc = "Index of the replica",
            default = 1,
        ),
        "port": attr.int(
            doc = "Internal port of the service. The port does not need to be published in the docker-compose file.",
            mandatory = True,
        ),
        "service_name": attr.string(
            doc = "Docker compose service name",
            mandatory = True,
        ),
    },
    implementation = _dc_service_reference_impl,
)
