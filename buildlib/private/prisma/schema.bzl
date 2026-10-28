"""prisma_schema rule."""

load("@bazel_lib//lib:copy_to_bin.bzl", "COPY_FILE_TO_BIN_TOOLCHAINS", "copy_file_to_bin_action")
load("@bazel_lib//lib:write_source_files.bzl", "write_source_files")
load(":providers.bzl", "PrismaSchemaInfo")

def _validate_schema(ctx, schema):
    validation_marker = ctx.actions.declare_file(ctx.label.name + ".validation")

    args = ctx.actions.args()
    args.add("--prismaCli", ctx.executable._prisma_tool)
    args.add("--schemaPath", schema)
    args.add("--validationMarker", validation_marker)
    ctx.actions.run(
        executable = ctx.executable._validate_schema_tool,
        arguments = [args],
        env = {"BAZEL_BINDIR": "."},
        inputs = [schema],
        tools = [
            ctx.executable._validate_schema_tool,
            ctx.executable._prisma_tool,
        ],
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

    return [
        DefaultInfo(
            files = depset([schema]),
        ),
        PrismaSchemaInfo(
            schema = schema,
        ),
        OutputGroupInfo(
            _validation = depset([validation_marker]),
        ),
    ]

_prisma_schema = rule(
    implementation = _prisma_schema_impl,
    attrs = {
        "formatted_schema": attr.output(),
        "schema": attr.label(
            mandatory = True,
            allow_single_file = [".prisma"],
        ),
        "_prisma_tool": attr.label(
            executable = True,
            cfg = "exec",
            default = "@prisma//:cli",
        ),
        "_validate_schema_tool": attr.label(
            default = Label("//private/prisma/src:validate-schema"),
            executable = True,
            cfg = "exec",
        ),
    },
    toolchains = COPY_FILE_TO_BIN_TOOLCHAINS,
)

def _prisma_schema_macro_impl(name, srcs, visibility, testonly):
    if len(srcs) != 1:
        # For now. TODO: Support multi-file schemas
        # https://www.prisma.io/docs/orm/prisma-schema/overview/location#multi-file-prisma-schema
        fail("srcs must have exactly one element (multi-file prisma schemas are not supported at the moment)")

    schema = srcs[0]

    _prisma_schema(
        name = name,
        schema = schema,
        formatted_schema = name + ".fmt.prisma",
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
        "srcs": attr.label_list(
            doc = "Schema file (only a single file is supported for now).",
            allow_files = [".prisma"],
            allow_empty = False,
            mandatory = True,
            configurable = False,
        ),
        "testonly": attr.bool(
            doc = "Testonly flag",
            default = False,
            configurable = False,
        ),
    },
    implementation = _prisma_schema_macro_impl,
)
