"""Rule to generate gql client types."""

load("@aspect_bazel_lib//lib:paths.bzl", "relative_file")
load("@aspect_rules_js//js:defs.bzl", "js_run_binary")
load("//private/ts:npm_js_binary.bzl", "npm_js_binary")

def _config_impl(ctx):
    cfg = {
        "documents": [
            relative_file(src.short_path, ctx.build_file_path)
            for src in ctx.files.srcs
        ],
        "generates": {
            ctx.attr.out_dir: {
                "plugins": [],
                "preset": "client",
                "presetConfig": {
                    "gqlTagName": "gql",
                },
            },
        },
        "schema": relative_file(ctx.file.gql_schema.short_path, ctx.build_file_path),
    }

    ctx.actions.write(
        content = json.encode(cfg),
        output = ctx.outputs.out_cfg,
    )

_config = rule(
    implementation = _config_impl,
    attrs = {
        "gql_schema": attr.label(allow_single_file = [".graphql"]),
        "out_cfg": attr.output(),
        "out_dir": attr.string(),
        "srcs": attr.label_list(allow_files = True),
    },
)

def gql_client_codegen(name, gql_schema, srcs = None, testonly = None):
    """Generates a typed graphql client.

    Example: [`@examples//frontend/src:gql`](../../examples/frontend/src/BUILD.bazel#:~:text=name%20%3D%20%22gql%22%2C)

    Args:
      name: Name of the rule. The generated client will be available for import
          from a directory with the same name.
      gql_schema: GraphQL schema to work off of.
      srcs: Source files containing GraphQL queries.
      testonly: Testonly flag.
    """

    if srcs == None:
        srcs = native.glob(["**/*.ts", "**/*.tsx"])

    npm_js_binary(
        name = name + ".bin",
        node_module = "@graphql-codegen/cli",
        entry_point = "cjs/bin.js",
        testonly = testonly,
    )

    cfg_name = name + ".config.json"

    _config(
        name = name + ".cfg",
        srcs = srcs,
        gql_schema = gql_schema,
        out_dir = "./{}/".format(name),
        out_cfg = cfg_name,
        testonly = testonly,
    )

    js_run_binary(
        name = name,
        tool = name + ".bin",
        chdir = native.package_name(),
        args = ["--config", cfg_name],
        srcs = srcs + [
            gql_schema,
            name + ".cfg",
            "//:node_modules/@graphql-codegen/client-preset",
        ],
        outs = [
            name + "/fragment-masking.ts",
            name + "/gql.ts",
            name + "/graphql.ts",
            name + "/index.ts",
        ],
        testonly = testonly,
    )
