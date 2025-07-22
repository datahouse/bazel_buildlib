"""prisma_generate rule."""

load("@aspect_rules_js//js:libs.bzl", "js_lib_helpers")
load("@bazel_skylib//lib:paths.bzl", "paths")
load("//private:npm_js_binary.bzl", "npm_js_binary")
load("//private/prisma:providers.bzl", "PrismaEnginesInfo", "PrismaGenerateInfo", "PrismaGeneratorInfo", "PrismaSchemaInfo")

def _prisma_generate_impl(ctx):
    cmd_parts = ["$2 generate --schema $3"]
    out_dirs = {}
    generate_deps = []
    exec_paths = []

    for generator in ctx.attr.generators:
        info = generator[PrismaGeneratorInfo]

        if info.exec_paths:
            exec_paths.extend(info.exec_paths)

        out_dir = ctx.actions.declare_directory(info.target_name)
        out_dirs[info.target_name] = out_dir

        # Add a `package.json` to define the module type.
        #
        # Using arguments would be cleaner than string formatting, but leads to
        # less readable code (we'd need to track argument numbers, more mutability, etc.)
        cmd_parts.append(
            "echo '{content}' > {path}/package.json".format(
                content = json.encode({"type": info.module_type}),
                path = out_dir.path,
            ),
        )

        generate_deps.extend(info.generate_deps)

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

    cmd = "PATH=\"$1:$PATH\" " + "&&".join(cmd_parts)

    ctx.actions.run_shell(
        command = cmd,
        arguments = [
            ":".join(exec_paths),
            ctx.executable.prisma.path,
            schema.short_path,
        ],
        inputs = inputs,
        tools = [ctx.executable.prisma],
        outputs = out_dirs.values(),
        # buildifier: disable=unsorted-dict-items
        env = {
            "BAZEL_BINDIR": ctx.bin_dir.path,

            # do not install @prisma/client
            "PRISMA_GENERATE_SKIP_AUTOINSTALL": "True",

            # Prisma engines.
            "PRISMA_SCHEMA_ENGINE_BINARY": paths.relativize(engines.schema_engine.path, ctx.bin_dir.path),
            "PRISMA_QUERY_ENGINE_BINARY": paths.relativize(engines.query_engine.path, ctx.bin_dir.path),
            "PRISMA_QUERY_ENGINE_LIBRARY": paths.relativize(engines.libquery_engine.path, ctx.bin_dir.path),

            # Set Prisma env variables for unused engines to make sure nothing gets downloaded.
            "PRISMA_FMT_BINARY": "unused",
            "PRISMA_INTROSPECTION_ENGINE_BINARY": "unused",
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
