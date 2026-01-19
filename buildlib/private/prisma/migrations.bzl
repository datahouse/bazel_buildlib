"""prisma_migrations macro."""

load("@aspect_rules_js//js:defs.bzl", "js_test")
load("@bazel_lib//lib:copy_to_bin.bzl", "COPY_FILE_TO_BIN_TOOLCHAINS", "copy_files_to_bin_actions")
load(":providers.bzl", "PrismaMigrationsInfo", "PrismaSchemaInfo")

def _prisma_schema_info_impl(ctx):
    i = ctx.attr.schema[PrismaSchemaInfo]
    ctx.actions.write(ctx.outputs.db_url_env_out, i.db_url_env)
    ctx.actions.write(ctx.outputs.db_type_out, i.db_type)

_prisma_schema_info = rule(
    implementation = _prisma_schema_info_impl,
    doc = "Glue rule to extract Prisma Schema provider info",
    attrs = {
        "db_type_out": attr.output(),
        "db_url_env_out": attr.output(),
        "schema": attr.label(providers = [PrismaSchemaInfo]),
    },
)

def _same_package(x, y):
    return x.repo_name == y.repo_name and x.package == y.package

def _prisma_migrations_impl(ctx):
    # Check we are in the same package as the schema.
    # Both prisma itself and some of our rules rely on this:
    # The location of the migrations is discovered relative to the schema location.
    if not _same_package(ctx.label, ctx.attr.schema.label):
        fail("prisma_migrations must be in the same package as the prisma_schema.")

    # Copy to bin for ease of use in rules_js rules.
    migrations = depset(copy_files_to_bin_actions(ctx, ctx.files.srcs))

    schema_info = ctx.attr.schema[PrismaSchemaInfo]

    return [
        PrismaMigrationsInfo(
            schema_info = schema_info,
            migrations = migrations,
        ),
        DefaultInfo(
            files = migrations,
            runfiles = ctx.runfiles(
                # prisma refuses to consume migrations without the schema.
                # so we pass it to the runfiles for ease of use.
                files = [schema_info.schema],
                transitive_files = migrations,
            ),
        ),
    ]

_prisma_migrations = rule(
    implementation = _prisma_migrations_impl,
    attrs = {
        "schema": attr.label(
            mandatory = True,
            providers = [PrismaSchemaInfo],
        ),
        "srcs": attr.label_list(
            mandatory = True,
            allow_files = True,
        ),
    },
    toolchains = COPY_FILE_TO_BIN_TOOLCHAINS,
)

def _prisma_migrations_macro_impl(name, srcs, schema, validation_db_image, visibility, testonly, tags):
    _prisma_migrations(
        name = name,
        srcs = srcs,
        schema = schema,
        visibility = visibility,
        testonly = testonly,
        tags = tags,
    )

    _prisma_schema_info(
        name = name + "_schema_info",
        schema = schema,
        db_url_env_out = name + "_db_url_env.txt",
        db_type_out = name + "_db_type.txt",
        testonly = testonly,
        tags = tags,
    )

    cli = Label("//prisma:cli")

    # Migration validation could technically be a validation action.
    # However, a test is more appropriate for at least the following reasons:
    # - Execution time:
    #   Migration validation takes order of seconds at least.
    #   This is much longer than we'd expect from a validation action.
    # - Resulting dependency graph:
    #   For example, iterating on RLS code can be done with (temporarily)
    #   inconsistent migrations. A failing validation action would prevent the
    #   target from being built (and hence used downstream).
    #   This might lower developer experience.
    #   A failing test on the other hand merely fails the overall build.
    js_test(
        name = name + "_test",
        entry_point = Label("//private/prisma/src:validate-migrations.js"),
        env = {
            "DB_IMAGE_DIR": "$(rootpath %s)" % validation_db_image,
            "DB_TYPE": "$(rootpath %s)" % (name + "_db_type.txt"),
            "DB_URL_ENV": "$(rootpath %s)" % (name + "_db_url_env.txt"),
            "PRISMA_CLI_PATH": "$(rootpath %s)" % cli,
            "PRISMA_SCHEMA_PATH": "$(rootpath %s)" % schema,
        },
        data = [
            Label("//private/prisma/src"),
            schema,
            cli,
            validation_db_image,
            name,
            name + "_db_type.txt",
            name + "_db_url_env.txt",
        ],
        tags = tags + [
            "requires-network",  # access to the db container.
        ],
        visibility = [
            # Hack: Friend for testing
            Label("//private/prisma/test/inconsistent_migrations:__pkg__"),
        ],
    )

prisma_migrations = macro(
    doc = """Declares and tests prisma migrations.

    The test verifies the migrations are consistent with the schema.
    In other words: if the test passes, running `prisma migrate dev` will not create a new migration.

    Example: [`@examples//prisma:migrations`](../../examples/prisma/BUILD.bazel#:~:text=name%20%3D%20%22migrations%22%2C)
    """,
    implementation = _prisma_migrations_macro_impl,
    attrs = {
        "schema": attr.label(
            doc = "The corresponding prisma_schema target.",
            mandatory = True,
            providers = [PrismaSchemaInfo],
            configurable = False,
        ),
        "srcs": attr.label_list(
            doc = """All files in the `migrations/` directory. Typically: `glob(["migrations/**"])`.""",
            mandatory = True,
            allow_files = True,
        ),
        "tags": attr.string_list(
            doc = "Tags",
            default = [],
            configurable = False,
        ),
        "testonly": attr.bool(
            doc = "Testonly flag",
            default = False,
            configurable = False,
        ),
        "validation_db_image": attr.label(
            doc = "The database image to use to validate schema/migration consistency.",
            allow_single_file = True,
            mandatory = True,
            configurable = False,
        ),
    },
)
