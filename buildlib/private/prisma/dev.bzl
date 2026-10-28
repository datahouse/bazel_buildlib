"""prisma_dev rule."""

load("@bazel_lib//lib:paths.bzl", "relative_file")
load("@bazel_skylib//lib:paths.bzl", "paths")
load("@prisma//:version.bzl", "PRISMA7_OR_ABOVE")
load("//private:launcher.bzl", "create_launcher")
load("//private/docker/compose:providers.bzl", "DcServiceReferenceInfo")
load(":providers.bzl", "PrismaSchemaInfo")

def _setup_prisma_seed(ctx, seed_script):
    """Creates a generated package.json configuring prisma to use the provided seed script.

    Returns exec dir and runfiles required for this.

    We run prisma in a dedicated execution directory so we can generate an ad-hoc
    package.json that contains the seed script config without interfering with
    other config in package.json (notably module config).

    Yes, this is not very nice, if prisma let us configure seeding via CLI
    flag or env variable, this would not be necessary.
    """

    rel_exec_dir = ctx.label.name + ".execdir"
    exec_dir = paths.join(ctx.label.package, rel_exec_dir)

    info = seed_script[DefaultInfo]

    package_path = paths.join(rel_exec_dir, "package.json")
    package_json = ctx.actions.declare_file(package_path)
    content = json.encode({
        "prisma": {
            "seed": relative_file(
                info.files_to_run.executable.short_path,
                paths.join(ctx.label.package, package_path),
            ),
        },
    })

    ctx.actions.write(package_json, content)

    return exec_dir, package_json

def _prisma_dev_impl(ctx):
    schema_info = ctx.attr.schema[PrismaSchemaInfo]
    prisma_info = ctx.attr._prisma_tool[DefaultInfo]
    service_ref = ctx.attr.db_service[DcServiceReferenceInfo]

    runfiles_direct = []
    runfiles_transitive = [
        prisma_info.default_runfiles,
    ]

    if ctx.attr.seed_script:
        runfiles_transitive.append(ctx.attr.seed_script[DefaultInfo].default_runfiles)

    runner_cfg = {
        "dbService": {
            "composeLabel": service_ref.compose_label,
            "index": service_ref.index,
            "port": service_ref.port,
            "project": service_ref.project,
            "service": service_ref.service,
        },
        "dbUrl": ctx.attr.db_url,
        "prismaTool": prisma_info.files_to_run.executable.short_path,
        "schemaPath": schema_info.schema.short_path,
    }

    if PRISMA7_OR_ABOVE:
        # Use internal env variable for DB URL to avoid having to run compose
        # service discovery inside the config. The env var is set in
        # dev-runner.ts and picked up by the prisma config at runtime.
        db_url_env = "DH_BUILDLIB_INTERNAL_PRISMA_DEV_DB_URL"

        # Write prisma config.
        prisma_cfg = ctx.actions.declare_file(ctx.label.name + ".prisma.config.js")

        ctx.actions.expand_template(
            template = ctx.file._prisma7_cfg_tpl,
            output = prisma_cfg,
            substitutions = {
                "{{DB_URL_ENV}}": json.encode(db_url_env),
                "{{SCHEMA_PATH}}": json.encode(schema_info.schema.short_path),
                "{{SEED_SCRIPT}}": json.encode(
                    ctx.executable.seed_script.short_path if ctx.executable.seed_script else None,
                ),
            },
        )

        runfiles_direct.append(prisma_cfg)

        runner_cfg["dbUrlEnv"] = db_url_env
        runner_cfg["prismaConfig"] = prisma_cfg.short_path
    elif ctx.attr.seed_script:
        exec_dir, package_json = _setup_prisma_seed(ctx, ctx.attr.seed_script)
        runner_cfg["prismaExecDir"] = exec_dir
        runfiles_direct.append(package_json)

    # Write runner config file.
    runner_cfg_file = ctx.actions.declare_file(ctx.label.name + ".runner.config.json")
    ctx.actions.write(runner_cfg_file, json.encode(runner_cfg))
    runfiles_direct.append(runner_cfg_file)

    # Create launcher.
    launcher = create_launcher(ctx, ctx.attr._dev_runner, fixed_args = [runner_cfg_file.short_path])
    runfiles_transitive.append(launcher.runfiles)

    runfiles = ctx.runfiles(files = runfiles_direct).merge_all(runfiles_transitive)

    return DefaultInfo(
        executable = launcher.executable,
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

            The host:port resolved by `db_service` will be placed into this URL.
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
        "_dev_runner": attr.label(
            default = Label("//private/prisma/src:dev-runner"),
            executable = True,
            cfg = "exec",
        ),
        "_prisma7_cfg_tpl": attr.label(
            allow_single_file = True,
            default = Label("//private/prisma:prisma7.dev.config.js.tpl"),
        ),
        "_prisma_tool": attr.label(
            executable = True,
            cfg = "exec",
            default = "@prisma//:cli",
        ),
    },
    executable = True,
    implementation = _prisma_dev_impl,
)
