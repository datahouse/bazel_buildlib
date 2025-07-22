"""prisma_client_js macro."""

load("@aspect_rules_js//js:defs.bzl", "js_library")
load("//private/prisma:generator_wiring.bzl", "prisma_generator_def", "prisma_generator_result")
load("//private/prisma:providers.bzl", "PrismaGenerateInfo")

def _prisma_client_js_impl(name, generate, visibility, testonly):
    prisma_generator_def(
        name = name + ".generator",
        deps = [
            "//:node_modules/@prisma/client",
        ],
        module_type = "commonjs",
        # Generate must be in the same package.
        visibility = ["//" + native.package_name() + ":__pkg__"],
        # Do not forward testonly: central generator may generate non-test targets.
    )

    prisma_generator_result(
        name = name + ".result",
        generate = generate,
        testonly = testonly,
    )

    js_library(
        name = name,
        srcs = [name + ".result"],
        deps = [
            "//:node_modules/@types/node",
        ],
        visibility = visibility,
        testonly = testonly,
    )

prisma_client_js = macro(
    doc = """Defines a prisma generator with the prisma-client-js provider.

    For a generator with name `<name>`, you need (at least) the following settings in the the Prisma Schema:

    ```
    generator <anything> {
      provider      = "prisma-client-js"
      output        = "<name>"
    }
    ```

    Example: [`@examples//prisma:prisma-client`](../../examples/prisma/BUILD.bazel#:~:text=name%20%3D%20%22prisma%2Dclient%22%2C)

    For more: https://www.prisma.io/docs/concepts/components/prisma-client/working-with-prismaclient/generating-prisma-client
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
    implementation = _prisma_client_js_impl,
)
