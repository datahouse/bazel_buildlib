"""node_binary_image rule to create a node docker image with a custom base.

This is by-and-large adapted from js_image_layer in rules_js. The notable differences are:
- We use the node version provided in the base image (rather than copying one in).
- We do not copy the bazel invocation instrumentation bash scripts but directly start node in the docker entrypoint.
"""

load("@aspect_rules_js//js:providers.bzl", "JsInfo")
load("@bazel_skylib//lib:paths.bzl", "paths")
load("@rules_oci//oci:defs.bzl", "oci_image")
load("//private/docker:js_image_layers.bzl", "js_image_layers")
load(":empty_dir_layer.bzl", "empty_dir_layer")

def _node_cmd_impl(ctx):
    cmd = "node\n%s" % paths.join("/app", ctx.file.entry_point.short_path)

    ctx.actions.write(ctx.outputs.out, cmd)

_node_cmd = rule(
    doc = """Tiny rule to create a CMD invoking node.

    Note that we could use aspect's expand_template for this. However, that
    would not protect us very well from incorrect usage, so we don't.
    """,
    attrs = {
        "entry_point": attr.label(allow_single_file = [".js"]),
        "out": attr.output(),
    },
    implementation = _node_cmd_impl,
)

# See buildlib/private/README.md#sym-macro-use-site-label-res
_default_base_image = "@node_image_linux_amd64"

def _node_binary_image_impl(
        name,
        entry_point,
        data,
        base,
        user,
        ports,
        volumes,
        platform,
        visibility,
        testonly):
    base = base or _default_base_image

    js_image_layers(
        name = name + ".layers",
        data = data,
        platform = platform,
        app_layer = name + ".app.tar.gz",
        node_modules_layer = name + ".node-modules.tar.gz",
        testonly = testonly,
    )

    tars = [
        name + ".node-modules.tar.gz",
        name + ".app.tar.gz",
    ]

    if volumes:
        empty_dir_layer(
            name = name + ".volumes",
            base = base,
            user = user,
            paths = volumes,
            out = name + ".volumes.tar.gz",
            testonly = testonly,
        )

        tars.insert(0, name + ".volumes.tar.gz")

    _node_cmd(
        name = name + ".cmd",
        entry_point = entry_point,
        out = name + ".cmd.txt",
        testonly = testonly,
    )

    oci_image(
        name = name,
        base = base,
        tars = tars,
        cmd = name + ".cmd.txt",
        user = user,
        workdir = "/app",
        volumes = volumes,
        exposed_ports = ports,
        visibility = visibility,
        testonly = testonly,
    )

node_binary_image = macro(
    doc = """Builds a docker image that runs the entry_point script.

    Example: [`@examples//api`](../../examples/api/BUILD.bazel#:~:text=name%20%3D%20%22api%22%2C)
    """,
    attrs = {
        "base": attr.label(
            doc = "docker base image, must contain the node binary. Defaults to: " + _default_base_image,
        ),
        "data": attr.label_list(
            doc = "ts_project(s) that are required for this app.",
            providers = [JsInfo],
            mandatory = True,
        ),
        "entry_point": attr.label(
            doc = "JS file that is to be run. The cmd of the created image will be `node <entry_point>`",
            allow_single_file = [".js"],
            mandatory = True,
        ),
        "platform": attr.label(
            doc = """Platform to build the dependencies that go into the image for.
              Mostly relevant for Prisma engines. Defaults to Debian Linux with OpenSSL 3.x.""",
            default = "//private/docker:node_default_platform",
        ),
        "ports": attr.string_list(
            doc = "Ports this image exposes (like EXPOSE in Dockerfile).",
            default = [],
            configurable = False,
        ),
        "testonly": attr.bool(
            doc = "testonly flag",
            default = False,
            configurable = False,
        ),
        "user": attr.string(
            doc = "User the image runs with (must exist in the base image).",
            default = "node",
        ),
        "volumes": attr.string_list(
            doc = """mount points this image uses (like VOLUME in Dockerfile).
              These should be full paths not names (e.g. `["/data"]`).
              For each of these, a directory owned by `user` is automatically created
              in the image (to allow the node process to actually write to it).
            """,
            default = [],
            configurable = False,
        ),
    },
    implementation = _node_binary_image_impl,
)
