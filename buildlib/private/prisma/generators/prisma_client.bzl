"""prisma_client macro."""

load("@aspect_rules_js//js:defs.bzl", "js_library", "js_run_binary")
load("@bazel_lib//lib:copy_to_directory.bzl", "copy_to_directory")
load("@bazel_skylib//lib:paths.bzl", "paths")
load("@bazel_skylib//rules:write_file.bzl", "write_file")
load("//private/prisma:generator_wiring.bzl", "prisma_generator_def", "prisma_generator_result")
load("//private/prisma:providers.bzl", "PrismaGenerateInfo")

def _prisma_client_impl(name, generate, visibility, testonly):
    prisma_generator_def(
        name = name + ".generator",
        deps = [
            "//:node_modules/@prisma/client",
        ],
        # Generate must be in the same package.
        visibility = ["//" + native.package_name() + ":__pkg__"],
        # Do not forward testonly: central generator may generate non-test targets.
    )

    prisma_generator_result(
        name = name + ".result",
        generate = generate,
        testonly = testonly,
    )

    js_run_binary(
        name = name + ".tsc",
        tool = "@npm_typescript//:tsc",
        args = [
            "--project",
            "tsconfig-base.json",
            "--outDir",
            paths.join(native.package_name(), name + ".tsc"),
            "--rootDir",
            paths.join(native.package_name(), name + ".result"),
        ],
        srcs = [
            name + ".result",
            # pull in tsconfig from the client repo!
            # requires friend declaration in ts_setup.
            "//:tsconfig-base",
        ],
        out_dirs = [name + ".tsc"],
        testonly = testonly,
    )

    # TODO(#711): Unfortunately, prisma client needs import.meta.url or __dirname.
    #
    # Since Jest does not support ESM yet (and our transpilation does not
    # rewrite import.meta.url). We have to resort to CJS.
    write_file(
        name = name + ".pkg",
        out = name + ".pkg/package.json",
        content = ["""{"type": "commonjs"}"""],
    )

    # Additional directory copy for
    # - assets (prisma engines).
    #   TODO(#1407): Check if this is still necessary with the rust free client.
    # - package.json for cjs.
    #   TODO(#711): Remove once jest supports ESM.
    copy_to_directory(
        name = name + ".assemble",
        srcs = [
            name + ".tsc",
            name + ".result",
            name + ".pkg",
        ],
        replace_prefixes = {
            name + ".tsc": "",
            name + ".result": "",
            name + ".pkg": "",
        },
        exclude_srcs_patterns = [
            name + ".result/**/*.ts",
        ],
        out = name,
        testonly = testonly,
    )

    js_library(
        name = name,
        srcs = [name + ".assemble"],
        deps = [
            "//:node_modules/@types/node",
            "//:node_modules/@prisma/client",
        ],
        visibility = visibility,
        testonly = testonly,
    )

prisma_client = macro(
    doc = """Defines a prisma generator with the prisma-client provider.

    Requires:
    - prisma >= 6.16.0.
    - typescript (enable_ts in buildlib_setup)

    For a generator with name `<name>`, you need (at least) the following settings in the the Prisma Schema:

    ```
    generator <anything> {
      provider            = "prisma-client"
      output              = "<name>"
      moduleFormat        = "cjs"
      importFileExtension = "js"
    }
    ```

    Example: [`@prisma-musl-no-typegraphql//prisma:client`](../../tests/prisma-musl-no-typegraphql/prisma/BUILD.bazel#:~:text=name%20%3D%20%22client%22%2C)

    For more: https://www.prisma.io/docs/orm/prisma-schema/overview/generators
    """,
    attrs = {
        "generate": attr.label(
            doc = "The prisma_generate target containing this generator",
            providers = [PrismaGenerateInfo],
            mandatory = True,
            configurable = False,
        ),
        "testonly": attr.bool(
            doc = "Testonly flag",
            default = False,
            configurable = False,
        ),
    },
    implementation = _prisma_client_impl,
)
