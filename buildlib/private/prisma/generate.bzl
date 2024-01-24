"""prisma_generate rule."""

load("@aspect_rules_js//js:defs.bzl", "js_library")
load("@aspect_rules_js//js:providers.bzl", "JsInfo")
load("@bazel_skylib//lib:paths.bzl", "paths")
load("@bazel_skylib//rules:select_file.bzl", "select_file")
load("//private/prisma:providers.bzl", "PrismaEnginesInfo", "PrismaSchemaInfo")
load("//private/ts:npm_js_binary.bzl", "npm_js_binary")
load(":node_modules_bin_path.bzl", "node_modules_bin_path")

def _prisma_generate_impl(ctx):
    out_dirs = [
        ctx.actions.declare_directory(out_dir)
        for out_dir in ctx.attr.out_dirs
    ]

    schema = ctx.attr.schema[PrismaSchemaInfo].schema

    engines = ctx.attr._prisma_engines[PrismaEnginesInfo]

    inputs = depset(
        direct = [
            schema,
            engines.query_engine,
            engines.libquery_engine,
            engines.schema_engine,
        ],
        transitive = [
            d[JsInfo].transitive_sources
            for d in ctx.attr.deps
        ] + [
            d[JsInfo].transitive_npm_linked_package_files
            for d in ctx.attr.deps
        ],
    )

    ctx.actions.run(
        executable = ctx.executable.prisma,
        arguments = ["generate", "--schema", schema.short_path],
        inputs = inputs,
        outputs = out_dirs,
        # buildifier: disable=unsorted-dict-items
        env = {
            "BAZEL_BINDIR": ctx.bin_dir.path,

            # Add node_modules/.bin to the path, so we can find typegraphql-prisma.
            "PATH": node_modules_bin_path("."),

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

    return DefaultInfo(files = depset(out_dirs))

_prisma_generate = rule(
    implementation = _prisma_generate_impl,
    attrs = {
        "deps": attr.label_list(providers = [JsInfo]),
        "out_dirs": attr.string_list(),
        "prisma": attr.label(
            executable = True,
            cfg = "exec",
        ),
        "schema": attr.label(
            providers = [PrismaSchemaInfo],
        ),
        "_prisma_engines": attr.label(
            providers = [PrismaEnginesInfo],
            default = Label("//private/prisma:engines"),
        ),
    },
)

def _provider_prisma_client_js():
    """The default Prisma Client provider.

    For a generator with name `<name>`, you need (at least) the following settings in the the Prisma Schema:

    ```
    generator <anything> {
      provider      = "prisma-client-js"
      output        = "<name>"
    }
    ```

    For more:
    https://www.prisma.io/docs/concepts/components/prisma-client/working-with-prismaclient/generating-prisma-client
    """

    def _build(name, input, visibility, testonly):
        js_library(
            name = name,
            srcs = [input],
            deps = [
                "//:node_modules/@types/node",
            ],
            visibility = visibility,
            testonly = testonly,
        )

    return struct(
        generate_deps = [
            "//:node_modules/@prisma/client",
        ],
        build_fun = _build,
    )

def _provider_typegraphql_prisma(prisma_client):
    """Typegraphql Prisma provider.

    For a generator with name `<name>`, you need (at least) the following settings in the the Prisma Schema:

    ```
    generator <anything> {
      provider           = "typegraphql-prisma"
      output             = "<name>"
      emitTranspiledCode = true
    }
    ```

    For more: https://prisma.typegraphql.com/docs/basics/configuration

    Args:
      prisma_client: Label (name) of the / a generator with prisma_client_js provider.
    """

    def _build(name, input, visibility, testonly):
        js_library(
            name = name,
            srcs = [input],
            deps = [
                "//:node_modules/@types/node",
                "//:node_modules/typegraphql-prisma",
                "//:node_modules/type-graphql",
                "//:node_modules/graphql",
                "//:node_modules/graphql-scalars",
                "//:node_modules/graphql-fields",
                "//:node_modules/@types/graphql-fields",
                "//:node_modules/class-validator",
                "//:node_modules/tslib",
                prisma_client,
            ],
            visibility = visibility,
            testonly = testonly,
        )

    return struct(
        generate_deps = [
            "//:node_modules/typegraphql-prisma",
            "//:node_modules/type-graphql",
        ],
        build_fun = _build,
    )

prisma_providers = struct(
    prisma_client_js = _provider_prisma_client_js,
    typegraphql_prisma = _provider_typegraphql_prisma,
)

_default_generators = {
    "prisma-client": prisma_providers.prisma_client_js(),
    "typegraphql-prisma": prisma_providers.typegraphql_prisma(
        prisma_client = ":prisma-client",
    ),
}

def prisma_generate(name, schema, generators = None, visibility = None, testonly = None):
    """Rule to set-up prisma client generation.

    The generators in the Prisma schema need to be in sync with the `generators` parameter:
    A dictionary from generated target names to the definition of the relevant provider
    (on the `prisma_providers` struct).

    A typical `generators` value for typegraphql-prisma would be:

    ```
    generators = {
        "prisma-client": prisma_providers.prisma_client_js(),
        "typegraphql-prisma": prisma_providers.typegraphql_prisma(
            prisma_client = ":prisma-client"
        ),
    }
    ```

    For now, this is the default, but the generators parameter will become mandatory in the future.

    Example: [`@examples//prisma:generate`](../../examples/prisma/BUILD.bazel#:~:text=name%20%3D%20%22generate%22%2C)

    Also see [`@examples//prisma:schema.prisma`](../../examples/prisma/schema.prisma) for an example schema.

    Args:
      name: name of the rule.
      schema: Prisma schema file (must be in the package directory).
      generators: Dictionary from generated target name to Prisma provider.
        The values in this dictionary must be obtained by calling one of the functions in prisma_providers.
      visibility: visibility of the generated targets.
      testonly: testonly flag for all targets.
    """

    if generators == None:
        generators = _default_generators
    elif not generators:
        fail("must have at least one generator")

    npm_js_binary(
        name = name + ".bin",
        node_module = "prisma",
        entry_point = "build/index.js",
        testonly = testonly,
    )

    _prisma_generate(
        name = name,
        schema = schema,
        out_dirs = generators.keys(),
        deps = [
            dep
            for gen in generators.values()
            for dep in gen.generate_deps
        ],
        prisma = name + ".bin",
    )

    for gen_name, gen in generators.items():
        select_file(
            name = gen_name + "-dir",
            srcs = name,
            subpath = gen_name,
            testonly = testonly,
        )

        gen.build_fun(
            name = gen_name,
            input = gen_name + "-dir",
            visibility = visibility,
            testonly = testonly,
        )
