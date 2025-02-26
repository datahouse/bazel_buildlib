"""prisma_generate rule."""

load("@aspect_rules_js//js:defs.bzl", "js_library")
load("@aspect_rules_js//js:libs.bzl", "js_lib_helpers")
load("@aspect_rules_js//js:providers.bzl", "JsInfo")
load("@bazel_skylib//lib:paths.bzl", "paths")
load("@bazel_skylib//rules:select_file.bzl", "select_file")
load("@bazel_skylib//rules:write_file.bzl", "write_file")
load("//private:npm_js_binary.bzl", "npm_js_binary")
load("//private/prisma:providers.bzl", "PrismaEnginesInfo", "PrismaSchemaInfo")

def _prisma_generate_impl(ctx):
    out_dirs = {
        out_dir: ctx.actions.declare_directory(out_dir)
        for out_dir in ctx.attr.out_dirs
    }

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
            ctx.attr.deps,
            include_sources = True,
            include_transitive_sources = True,
            include_npm_sources = True,
            include_types = False,
            include_transitive_types = False,
        )],
    )

    cmd = "PATH=\"$1:$PATH\" " + "&&".join([
        "$2 generate --schema $3",
    ] + [
        # Add a `package.json` to define the module type.
        #
        # Using arguments would be cleaner than string formatting, but leads to
        # less readable code (we'd need to track argument numbers, more mutability, etc.)
        "echo '{content}' > {path}/package.json".format(
            content = json.encode({"type": module_type}),
            path = out_dirs[out_dir].path,
        )
        for out_dir, module_type in ctx.attr.out_dirs.items()
    ])

    ctx.actions.run_shell(
        command = cmd,
        arguments = [
            ":".join(ctx.attr.exec_paths),
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

    return DefaultInfo(files = depset(out_dirs.values()))

_prisma_generate = rule(
    implementation = _prisma_generate_impl,
    attrs = {
        "deps": attr.label_list(providers = [JsInfo]),
        "exec_paths": attr.string_list(),
        "out_dirs": attr.string_dict(
            doc = "Dictionary from directory name to module type",
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

    def _macro(name, input, visibility, testonly):
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
            module_type = "commonjs",
            exec_paths = [],
        )

    return _macro

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

    def _macro(name, input, visibility, testonly):
        # Write an executable that invokes typegraphql-prisma.
        # node_modules/.bin would also contain this, but rules_js does not support it:
        # https://github.com/pnpm/pnpm/issues/5131#issuecomment-1824819472
        write_file(
            name = name + ".bin",
            out = name + ".bin/typegraphql-prisma",
            is_executable = True,
            content = [
                "#! /bin/sh",
                "node node_modules/typegraphql-prisma/lib/generator.js",
            ],
        )

        js_library(
            name = name + ".genlib",
            srcs = [name + ".bin"],
        )

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
                name + ".genlib",
            ],
            module_type = "commonjs",
            exec_paths = [paths.join(native.package_name(), name + ".bin")],
        )

    return _macro

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

    gen_out_dirs = {}
    gen_deps = []
    gen_exec_paths = []

    for gen_name, gen in generators.items():
        select_file(
            name = gen_name + "-dir",
            srcs = name,
            subpath = gen_name,
            testonly = testonly,
        )

        info = gen(
            name = gen_name,
            input = gen_name + "-dir",
            visibility = visibility,
            testonly = testonly,
        )

        gen_out_dirs[gen_name] = info.module_type
        gen_deps.extend(info.generate_deps)
        gen_exec_paths.extend(info.exec_paths)

    _prisma_generate(
        name = name,
        schema = schema,
        out_dirs = gen_out_dirs,
        deps = gen_deps,
        exec_paths = gen_exec_paths,
        prisma = name + ".bin",
    )
