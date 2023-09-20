"""prisma_dev rule."""

load("@bazel_skylib//lib:paths.bzl", "paths")
load("//private/docker:providers.bzl", "DcServiceReferenceInfo")
load("//private/prisma:providers.bzl", "PrismaSchemaInfo")

def _setup_prisma_seed(ctx, seed_script):
    """Creates a generated package.json configuring prisma to use the provided seed script.

    Returns runfiles required for this.
    """

    info = seed_script[DefaultInfo]

    package_json = ctx.actions.declare_file("package.json")
    content = json.encode({
        "prisma": {
            "seed": info.files_to_run.executable.short_path,
        },
    })

    ctx.actions.write(package_json, content)

    return ctx.runfiles(files = [package_json]).merge(info.default_runfiles)

def _prisma_dev_impl(ctx):
    schema_info = ctx.attr.schema[PrismaSchemaInfo]
    prisma_info = ctx.attr._prisma_tool[DefaultInfo]
    service_info = ctx.attr.db_service[DefaultInfo]
    service_executable = service_info.files_to_run.executable

    runfiles_transitive = [
        prisma_info.default_runfiles,
        service_info.default_runfiles,
    ]

    if ctx.attr.seed_script:
        seed_runfiles = _setup_prisma_seed(ctx, ctx.attr.seed_script)
        runfiles_transitive.append(seed_runfiles)

    runfiles = ctx.runfiles(files = [service_executable]).merge_all(runfiles_transitive)

    executable = ctx.actions.declare_file(ctx.label.name + ".sh")

    ctx.actions.expand_template(
        template = ctx.file._run_tpl,
        output = executable,
        is_executable = True,
        substitutions = {
            "{{DB_ENV_VAR}}": schema_info.db_url_env,
            "{{DB_URL}}": ctx.attr.db_url,
            "{{DOCKER_SERVICE_REF_BIN}}": paths.join(ctx.workspace_name, service_executable.short_path),
            "{{PRISMA_TOOL}}": paths.join(ctx.workspace_name, prisma_info.files_to_run.executable.short_path),
            "{{SCHEMA_PATH}}": schema_info.schema.short_path,
        },
    )

    return DefaultInfo(
        executable = executable,
        runfiles = runfiles,
    )

prisma_dev = rule(
    doc = """Run the prisma CLI against a docker compose managed database.

Example: [`@examples//prisma`](../../examples/prisma/BUILD.bazel#:~:text=name%20%3D%20%22prisma%22%2C)
    """,
    attrs = {
        "db_service": attr.label(
            doc = """dc_service_reference of the database to connect to.""",
            mandatory = True,
            providers = [DcServiceReferenceInfo],
        ),
        "db_url": attr.string(
            doc = """Database URL template to connect to.

            The env variable DB_SERVICE is available for substitution and will be
            set with the location of the discovered db_service (`host:port`).
            """,
            mandatory = True,
        ),
        "schema": attr.label(
            doc = """Schema to run with.""",
            mandatory = True,
            providers = [PrismaSchemaInfo],
        ),
        "seed_script": attr.label(
            doc = """Executable passed as seed script to prisma (optional).""",
            executable = True,
            cfg = "exec",
        ),
        "_prisma_tool": attr.label(
            executable = True,
            cfg = "exec",
            default = "@prisma//:cli",
        ),
        "_run_tpl": attr.label(
            allow_single_file = True,
            default = Label("//private/prisma:dev-run.tpl.sh"),
        ),
    },
    executable = True,
    implementation = _prisma_dev_impl,
)
