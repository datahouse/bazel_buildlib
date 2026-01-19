"""prisma_generate rule."""

load("@aspect_rules_js//js:libs.bzl", "js_lib_helpers")
load("//private:npm_js_binary.bzl", "npm_js_binary")
load("//private/prisma:providers.bzl", "PrismaEnginesInfo", "PrismaGenerateInfo", "PrismaGeneratorInfo", "PrismaSchemaInfo")

def _prisma_generate_impl(ctx):
    args = ctx.actions.args()
    out_dirs = {}
    generate_deps = []

    for generator in ctx.attr.generators:
        info = generator[PrismaGeneratorInfo]

        out_dir = ctx.actions.declare_directory(info.target_name + ".result")
        out_dirs[info.target_name] = out_dir

        generate_deps.extend(info.generate_deps)

        args.add_all("--execPath", info.exec_paths)
        args.add("--outDir", out_dir.path)

    schema = ctx.attr.schema[PrismaSchemaInfo].schema

    engines = ctx.attr._prisma_engines[PrismaEnginesInfo]

    inputs = depset(
        direct = [
            schema,
            engines.query_engine,
            engines.libquery_engine,
            engines.schema_engine,
        ],
        transitive = [js_lib_helpers.gather_files_from_js_infos(
            generate_deps,
            include_sources = True,
            include_transitive_sources = True,
            include_npm_sources = True,
            include_types = False,
            include_transitive_types = False,
        )],
    )

    args.add("--cliPath", ctx.executable.prisma)
    args.add("--queryEngineBinary", engines.query_engine)
    args.add("--queryEngineLibrary", engines.libquery_engine)
    args.add("--schemaEngineBinary", engines.schema_engine)
    args.add("--schemaPath", schema.short_path)
    args.add("--binDir", ctx.bin_dir.path)

    ctx.actions.run(
        inputs = inputs,
        tools = [ctx.executable.prisma],
        outputs = out_dirs.values(),
        arguments = [args],
        executable = ctx.executable._builder,
        env = {
            "BAZEL_BINDIR": ".",
        },
    )

    return [PrismaGenerateInfo(out_dirs = out_dirs)]

_prisma_generate = rule(
    implementation = _prisma_generate_impl,
    attrs = {
        "generators": attr.label_list(
            providers = [PrismaGeneratorInfo],
            allow_empty = False,
            mandatory = True,
        ),
        "prisma": attr.label(
            executable = True,
            cfg = "exec",
        ),
        "schema": attr.label(
            providers = [PrismaSchemaInfo],
        ),
        "_builder": attr.label(
            default = Label("//private/prisma/src:generate"),
            executable = True,
            cfg = "exec",
        ),
        "_prisma_engines": attr.label(
            providers = [PrismaEnginesInfo],
            default = Label("@prisma//:engines"),
        ),
    },
)

def _prisma_generate_macro_impl(
        name,
        schema,
        generators,
        visibility,  # @unused friend visibility declarations only by design.
        testonly):
    npm_js_binary(
        name = name + ".bin",
        node_module = "prisma",
        entry_point = "build/index.js",
        testonly = testonly,
    )

    _prisma_generate(
        name = name,
        schema = schema,
        generators = generators,
        prisma = name + ".bin",
        # Generators must be in the same package.
        visibility = ["//" + native.package_name() + ":__pkg__"],
    )

prisma_generate = macro(
    doc = """Rule to run prisma generation

    To use this rule, you need to define at least one prisma generator and pass
    it in the `generators` parameter.

    See [prisma_generators.md](./prisma_generators.md) for available generators.

    The generators defined in the Prisma schema need to be in sync with the
    `generators` parameter. Each generator rule specifies how the `generator`
    definition in the Prisma schema needs to look.

    To link a generator to `prisma_generate`, you have to:
    - Add a special target ending in `.generator` to `generators`
    - Pass the prisma_generate target to the generator

    ```bzl
    prisma_generate(
      name = "generate",
      generators = [":client.generator"],
      schema = "...",
    )

    prisma_client_js(
      name = "client",
      generate = ":generate",
    )
    ```

    Example: [`@examples//prisma:generate`](../../examples/prisma/BUILD.bazel#:~:text=name%20%3D%20%22generate%22%2C)

    Also see [`@examples//prisma:schema.prisma`](../../examples/prisma/schema.prisma) for an example schema.
    """,
    attrs = {
        "generators": attr.label_list(
            doc = "The generators to link to",
            providers = [PrismaGeneratorInfo],
            mandatory = True,
            allow_empty = False,
            configurable = False,
        ),
        "schema": attr.label(
            doc = "Prisma schema (must be in the same package)",
            mandatory = True,
            providers = [PrismaSchemaInfo],
            configurable = False,
        ),
        "testonly": attr.bool(
            doc = "Testonly flag",
            default = False,
            configurable = False,
        ),
    },
    implementation = _prisma_generate_macro_impl,
)
