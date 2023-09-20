"""Rules to reference docker-compose services."""

load("@io_bazel_rules_docker//skylib:docker.bzl", "docker_path")
load(":providers.bzl", "DcServiceReferenceInfo", "DockerComposeInfo")

def _dc_service_reference_impl(ctx):
    docker_toolchain = ctx.toolchains["@io_bazel_rules_docker//toolchains/docker:toolchain_type"].info

    executable = ctx.actions.declare_file(ctx.label.name + "-load-service-ref.sh")

    dc_info = ctx.attr.dc[DockerComposeInfo]

    # TODO: We should use a fake dc_file here (without real image refs).
    # This would avoid re-building the entire composition for the mere purpose of
    # getting the service reference.
    dc_file = dc_info.file

    # TODO: We should add a validate action that verifies the service,
    # port and index are correct.

    ctx.actions.expand_template(
        template = ctx.file._load_service_ref_tpl,
        output = executable,
        is_executable = True,
        substitutions = {
            "{{COMPOSE_FILE}}": dc_file.short_path,
            "{{COMPOSE_LABEL}}": str(ctx.attr.dc.label),
            "{{COMPOSE_PROJECT}}": dc_info.project,
            "{{DOCKER_CLI}}": docker_path(docker_toolchain),
            "{{SERVICE_INDEX}}": str(ctx.attr.index),
            "{{SERVICE_NAME}}": ctx.attr.service_name,
            "{{SERVICE_PORT}}": str(ctx.attr.port),
        },
    )

    runfiles = ctx.runfiles(files = [dc_file])

    return [
        DcServiceReferenceInfo(),
        DefaultInfo(
            executable = executable,
            runfiles = runfiles,
        ),
    ]

dc_service_reference = rule(
    doc = """Reference to an exposed port of a docker service.

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
            doc = "Internal port of the service",
            mandatory = True,
        ),
        "service_name": attr.string(
            doc = "Docker compose service name",
            mandatory = True,
        ),
        "_load_service_ref_tpl": attr.label(
            allow_single_file = True,
            default = Label("//private/docker:load-service-ref.tpl.sh"),
        ),
    },
    implementation = _dc_service_reference_impl,
    executable = True,
    toolchains = ["@io_bazel_rules_docker//toolchains/docker:toolchain_type"],
)
