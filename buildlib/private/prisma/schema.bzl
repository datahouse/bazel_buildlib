"""prisma_schema rule."""

load("@bazel_lib//lib:copy_to_bin.bzl", "COPY_FILE_TO_BIN_TOOLCHAINS", "copy_file_to_bin_action")
load("@bazel_lib//lib:write_source_files.bzl", "write_source_files")
load(":providers.bzl", "PrismaSchemaInfo")

def _validate_schema(ctx, schema):
    validation_marker = ctx.actions.declare_file(ctx.label.name + ".validation")

    ctx.actions.run_shell(
        command = "$1 validate --schema $2 && touch $3",
        arguments = [
            ctx.executable._prisma_tool.path,
            schema.path,
            validation_marker.path,
        ],
        env = {
            "BAZEL_BINDIR": ".",
            ctx.attr.db_url_env: ctx.attr.validate_db_url,
        },
        inputs = [schema],
        tools = [ctx.executable._prisma_tool],
        outputs = [validation_marker],
    )

    return validation_marker

def _format_schema(ctx, schema):
    ctx.actions.run_shell(
        # Use cat and pipes to avoid mode preservation,
        # (otherwise the target file would be read-only).
        # A cleaner option would be `cp --no-preserve-mode`, but MacOSX does not
        # support this.
        # And yes, we do all this, because prisma format does not support
        # specifying a different output file.
        command = "cat $2 > $3 && $1 format --schema $3",
        arguments = [
            ctx.executable._prisma_tool.path,
            schema.path,
            ctx.outputs.formatted_schema.path,
        ],
        env = {"BAZEL_BINDIR": "."},
        inputs = [schema],
        outputs = [ctx.outputs.formatted_schema],
        tools = [ctx.executable._prisma_tool],
    )

def _prisma_schema_impl(ctx):
    schema = copy_file_to_bin_action(ctx, ctx.file.schema)

    validation_marker = _validate_schema(ctx, schema)

    _format_schema(ctx, schema)

    # Split off schema from url to get db_type.
    # TODO: We should probably invert this at some point:
    # Take in the db_type and construct the URL.
    # Kept like this for backwards compatibility.
    db_type, _, _ = ctx.attr.validate_db_url.partition(":")

    return [
        DefaultInfo(
            files = depset([schema]),
        ),
        PrismaSchemaInfo(
            schema = schema,
            db_url_env = ctx.attr.db_url_env,
            db_type = db_type,
        ),
        OutputGroupInfo(
            _validation = depset([validation_marker]),
        ),
    ]

_prisma_schema = rule(
    implementation = _prisma_schema_impl,
    attrs = {
        "db_url_env": attr.string(
            mandatory = True,
        ),
        "formatted_schema": attr.output(),
        "schema": attr.label(
            mandatory = True,
            allow_single_file = [".prisma"],
        ),
        "validate_db_url": attr.string(
            mandatory = True,
        ),
        "_prisma_tool": attr.label(
            executable = True,
            cfg = "exec",
            default = "@prisma//:cli",
        ),
    },
    toolchains = COPY_FILE_TO_BIN_TOOLCHAINS,
)

def _prisma_schema_macro_impl(name, schema, db_url_env, validate_db_url, visibility, testonly):
    _prisma_schema(
        name = name,
        schema = schema,
        formatted_schema = name + ".fmt.prisma",
        db_url_env = db_url_env,
        validate_db_url = validate_db_url,
        testonly = testonly,
        visibility = visibility,
    )

    write_source_files(
        name = name + ".format",
        testonly = testonly,
        # Disable use of glob inside write_source_files.
        # We do not need a check that the file exists: it is an input to the macro.
        # So if it doesn't exist, the macro will not even get invoked.
        check_that_out_file_exists = False,
        files = {
            schema.name: name + ".fmt.prisma",
        },
    )

prisma_schema = macro(
    doc = """Declares a prisma schema, including a validation test.

    Example: [`@examples//prisma:schema`](../../examples/prisma/BUILD.bazel#:~:text=name%20%3D%20%22schema%22%2C)
    """,
    attrs = {
        "db_url_env": attr.string(
            doc = "Environment variable name to use for the database URL.",
            mandatory = True,
        ),
        "schema": attr.label(
            doc = "schema file",
            allow_single_file = [".prisma"],
            mandatory = True,
            configurable = False,
        ),
        "testonly": attr.bool(
            doc = "Testonly flag",
            default = False,
            configurable = False,
        ),
        "validate_db_url": attr.string(
            doc = """Database URL to use when validating the schema.
            This URL only needs to be structurally valid (no db needs to run there).""",
            mandatory = True,
        ),
    },
    implementation = _prisma_schema_macro_impl,
)
