"""prisma_deploy_image macro."""

load("@aspect_bazel_lib//lib:tar.bzl", "mtree_mutate", "mtree_spec", "tar")
load("@rules_oci//oci:defs.bzl", "oci_image")
load("//private/docker:js_image_layers.bzl", "js_image_layers")
load(":providers.bzl", "PrismaEnginesInfo", "PrismaMigrationsInfo")

# See buildlib/private/README.md#sym-macro-use-site-label-res
_base_default = "@node_image_linux_amd64"

def _platform_transition_impl(_, attr):
    return {
        # Transition into the right target platform.
        "//command_line_option:platforms": str(attr.platform),
    }

_platform_transition = transition(
    implementation = _platform_transition_impl,
    inputs = [],
    outputs = [
        "//command_line_option:platforms",
    ],
)

def _generate_engines_content_impl(ctx):
    engines_info = ctx.attr.engines[PrismaEnginesInfo]
    engines = [engines_info.query_engine, engines_info.libquery_engine, engines_info.schema_engine]

    mtree_spec_content = [
        # mtree spec requires newline at end of last entry
        "prisma-engines/%s uid=0 gid=0 time=0 mode=0755 type=file content=%s\n" % (e.basename, e.path)
        for e in engines
    ]

    ctx.actions.write(
        output = ctx.outputs.mtree_spec,
        content = "".join(mtree_spec_content),
    )

    env_var_file_content = [
        "PRISMA_QUERY_ENGINE_BINARY=/prisma-engines/%s" % engines_info.query_engine.basename,
        "PRISMA_QUERY_ENGINE_LIBRARY=/prisma-engines/%s" % engines_info.libquery_engine.basename,
        "PRISMA_SCHEMA_ENGINE_BINARY=/prisma-engines/%s" % engines_info.schema_engine.basename,
    ]
    ctx.actions.write(
        output = ctx.outputs.env_vars,
        content = "\n".join(env_var_file_content),
    )
    return [
        DefaultInfo(
            files = depset(engines),
        ),
    ]

_generate_engines_content = rule(
    implementation = _generate_engines_content_impl,
    attrs = {
        "engines": attr.label(
            providers = [PrismaEnginesInfo],
        ),
        "env_vars": attr.output(),
        "mtree_spec": attr.output(),
        "platform": attr.label(),
    },
    cfg = _platform_transition,
)

def _get_prisma_schema_impl(ctx):
    info = ctx.attr.migrations[PrismaMigrationsInfo]
    return [DefaultInfo(files = depset([info.schema_info.schema]))]

_get_prisma_schema = rule(
    implementation = _get_prisma_schema_impl,
    attrs = {
        "migrations": attr.label(providers = [PrismaMigrationsInfo]),
    },
)

def _prisma_deploy_image_impl(
        name,
        migrations,
        base,
        platform,
        visibility,
        testonly):
    base = base or _base_default

    js_image_layers(
        name = name + ".layers",
        data = [
            "//:node_modules/prisma",
        ],
        app_layer = name + ".app.tar.gz",
        node_modules_layer = name + ".node-modules.tar.gz",
        platform = platform,
        testonly = testonly,
    )

    _generate_engines_content(
        name = name + ".platform_specific_engines",
        engines = Label("@prisma//:engines"),
        platform = platform,
        mtree_spec = name + ".engines.mtree_spec",
        env_vars = name + ".engines.env_vars",
        testonly = testonly,
    )

    tar(
        name = name + ".engines",
        srcs = [name + ".platform_specific_engines"],
        mtree = name + ".engines.mtree_spec",
        testonly = testonly,
    )

    launcher = Label(":image-cli-launcher.sh")

    _get_prisma_schema(
        name = name + ".schema",
        migrations = migrations,
        testonly = testonly,
    )

    tar(
        name = name + ".launcher",
        srcs = [launcher, name + ".schema"],
        mtree = [
            "app/schema.prisma    uid=0 gid=0 time=0 mode=0644 type=file content=$(location %s)" % (name + ".schema"),
            "usr/local/bin/prisma uid=0 gid=0 time=0 mode=0755 type=file content=$(location %s)" % launcher,
        ],
        testonly = testonly,
    )

    mtree_spec(
        name = name + ".migrations_mtree",
        srcs = [migrations],
        testonly = testonly,
    )

    mtree_mutate(
        name = name + ".migrations_mtree_cleaned",
        mtree = name + ".migrations_mtree",
        package_dir = "app",
        strip_prefix = migrations.package,
        testonly = testonly,
    )

    tar(
        name = name + ".migrations",
        srcs = [migrations],
        mtree = name + ".migrations_mtree_cleaned",
        testonly = testonly,
    )

    tars = [
        name + ".node-modules.tar.gz",
        name + ".app.tar.gz",
        name + ".engines",
        name + ".launcher",
        name + ".migrations",
    ]

    oci_image(
        name = name,
        base = base,
        tars = tars,
        user = "node",
        cmd = ["prisma", "migrate", "deploy"],
        env = name + ".engines.env_vars",
        workdir = "/app",
        testonly = testonly,
        visibility = visibility,
    )

prisma_deploy_image = macro(
    doc = """Creates a docker image to run `prisma migrate deploy`

    The image is intended to be used for upgrading database schemas in production environments.

    Example: [`@examples//prisma:db-migrate`](../../examples/prisma/BUILD.bazel#:~:text=name%20%3D%20%22db%2Dmigrate%22%2C)
    """,
    attrs = {
        "base": attr.label(
            doc = "base image to use. defaults to: " + _base_default,
        ),
        "migrations": attr.label(
            doc = "set of migrations to be included in the deploy image",
            mandatory = True,
            configurable = False,
            providers = [PrismaMigrationsInfo],
        ),
        "platform": attr.label(
            doc = "Platform of the base image.",
            default = "//private/docker:node_default_platform",
        ),
        "testonly": attr.bool(
            doc = "testonly flag",
            default = False,
            configurable = False,
        ),
    },
    implementation = _prisma_deploy_image_impl,
)
