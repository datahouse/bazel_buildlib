"""typegraphql_prisma macro."""

load("@aspect_rules_js//js:defs.bzl", "js_library")
load("@aspect_rules_js//js:providers.bzl", "JsInfo")
load("@bazel_skylib//lib:paths.bzl", "paths")
load("@bazel_skylib//rules:write_file.bzl", "write_file")
load("//private/prisma:generator_wiring.bzl", "prisma_generator_def", "prisma_generator_result")
load("//private/prisma:providers.bzl", "PrismaGeneratorInfo")
load(":postprocess_utils.bzl", "declare_commonjs")

def _typegraphql_prisma_impl(name, generate, prisma_client, visibility, testonly):
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
        # Do not forward testonly: central generator may generate non-test targets.
    )

    js_library(
        name = name + ".genlib",
        srcs = [name + ".bin"],
        # Do not forward testonly: central generator may generate non-test targets.
    )

    prisma_generator_def(
        name = name + ".generator",
        deps = [
            "//:node_modules/typegraphql-prisma",
            "//:node_modules/type-graphql",
            name + ".genlib",
        ],
        exec_paths = [paths.join(native.package_name(), name + ".bin")],
        # Generate must be in the same package.
        visibility = ["//" + native.package_name() + ":__pkg__"],
        # Do not forward testonly: central generator may generate non-test targets.
    )

    prisma_generator_result(
        name = name + ".result",
        generate = generate,
        testonly = testonly,
    )

    declare_commonjs(
        name = name + ".proc",
        raw_result = name + ".result",
        out_dir = name,
        testonly = testonly,
    )

    js_library(
        name = name,
        srcs = [name + ".proc"],
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

typegraphql_prisma = macro(
    doc = """Defines a prisma generator with the typegraphql-prisma provider.

    For a generator with name `<name>`, you need (at least) the following settings in the the Prisma schema:

    ```
    generator <anything> {
      provider           = "typegraphql-prisma"
      output             = "<name>"
      emitTranspiledCode = true
    }
    ```

    Example: [`@examples//prisma:typegraphql-prisma`](../../examples/prisma/BUILD.bazel#:~:text=name%20%3D%20%22typegraphql%2Dprisma%22%2C)

    For more: https://prisma.typegraphql.com/docs/basics/configuration
    """,
    attrs = {
        "generate": attr.label(
            doc = "The prisma_generate target containing this generator",
            providers = [PrismaGeneratorInfo],
            mandatory = True,
            configurable = False,
        ),
        "prisma_client": attr.label(
            doc = "The prisma client to use in the generated resolvers",
            mandatory = True,
            providers = [JsInfo],
            configurable = False,
        ),
        "testonly": attr.bool(
            doc = "Testonly flag",
            default = False,
            configurable = False,
        ),
    },
    implementation = _typegraphql_prisma_impl,
)
