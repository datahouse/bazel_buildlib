"""Rule to generate a GraphQL schema file from a GraphQL value (in typescript)."""

load("@aspect_rules_js//js:defs.bzl", "js_run_binary")
load("@bazel_skylib//rules:copy_file.bzl", "copy_file")
load("//private/ts:js_binary.bzl", "js_binary")

def gql_schema(name, schema_import, out, deps = [], visibility = None, testonly = None):
    """Generate a .graphql file by importing TS code defining a schema.

    Example: [`@examples//api:schema`](../../examples/api/BUILD.bazel#:~:text=name%20%3D%20%22schema%22%2C)

    Args:
      name: Name of the resulting rule.
      schema_import: Path to import the schema generation function from.
          - The function must be the default export of the module.
          - The function must be async and not take any parameters.
      out: .graphql file to output to (typically schema.graqphl).
      deps: Typescript dependencies so the import works.
      visibility: Visibility of the schema.
      testonly: Testonly flag.
    """

    copy_file(
        name = name + ".generator",
        src = Label("//private/gql/src:gen-schema.js"),
        out = name + ".generator.js",
        testonly = testonly,
    )

    js_binary(
        name = name + ".bin",
        data = deps + [
            "//:node_modules/reflect-metadata",
            "//:node_modules/type-graphql",
        ],
        entry_point = name + ".generator.js",
        testonly = testonly,
    )

    js_run_binary(
        name = name,
        outs = [out],
        args = [schema_import, out],
        chdir = native.package_name(),
        use_execroot_entry_point = False,  # otherwise transitions don't work correctly.
        tool = name + ".bin",
        visibility = visibility,
        testonly = testonly,
    )
