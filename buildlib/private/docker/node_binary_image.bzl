"""node_binary_image rule to create a node docker image with a custom base.

This is by-and-large adapted from js_image_layer in rules_js. The notable differences are:
- We use the node version provided in the base image (rather than copying one in).
- We do not copy the bazel invocation instrumentation bash scripts but directly start node in the docker entrypoint.
"""

load("@bazel_skylib//lib:paths.bzl", "paths")
load("@rules_oci//oci:defs.bzl", "oci_image")
load("//private/docker:js_image_layers.bzl", "js_image_layers")
load(":empty_dir_layer.bzl", "empty_dir_layer")

def _node_cmd_impl(ctx):
    cmd = "node,%s" % paths.join("/app", ctx.file.entry_point.short_path)

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

def node_binary_image(
        name,
        entry_point,
        data,
        base = "@node_image",
        user = "node",
        ports = [],
        volumes = [],
        platform = Label("//private/docker:node_default_platform"),
        visibility = None,
        testonly = None):
    """Builds a docker image that runs the entry_point script.

    Example: [`@examples//api`](../../examples/api/BUILD.bazel#:~:text=name%20%3D%20%22api%22%2C)

    Args:
      name: name of the target.
      data: ts_project(s) that are required for this app.
      entry_point: JS file that is to be run.
        The cmd of the created image will be `node <entry_point>`
      base: docker base image, must contain the node binary.
      user: User the image runs with (must exist in the base image).
      ports: Ports this image exposes (like EXPOSE in Dockerfile).
      volumes: mount points this image uses (like VOLUME in Dockerfile).
        These should be full paths not names (e.g. `["/data"]`).
        For each of these, a directory owned by `user` is automatically created
        in the image (to allow the node process to actually write to it).

        Note: Due to a missing feature in rules_oci
        ([rules_oci#406](https://github.com/bazel-contrib/rules_oci/issues/406)),
        setting this does currently not set the volume paths on the resulting
        image.

        Since volumes are just metadata which we do not really use, this is OK-ish.

      platform: Platform to build the dependencies that go into the image for.
        Mostly relevant for Prisma engines. Defaults to Debian Linux with OpenSSL 3.x.
      visibility: visibility of the main target.
      testonly: testonly flag.
    """

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
        # TODO: Set volumes here, once rules_oci supports it.
        exposed_ports = ports,
        visibility = visibility,
        testonly = testonly,
    )
