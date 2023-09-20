"""node_binary_image rule to create a node docker image with a custom base.

This is by-and-large adapted from js_image_layer in rules_js. The notable differences are:
- We use the node version provided in the base image (rather than copying one in).
- We do not copy the bazel invocation instrumentation bash scripts but directly start node in the docker entrypoint.
"""

load("@bazel_skylib//lib:dicts.bzl", "dicts")
load("@bazel_skylib//lib:paths.bzl", "paths")
load("@io_bazel_rules_docker//container:image.bzl", "image")
load("//private/docker:js_image_layers.bzl", "js_image_layers")
load(":empty_dir_layer.bzl", "empty_dir_layer")

def _node_image_impl(ctx):
    cmd = ["node", paths.join("/app", ctx.file.entry_point.short_path)]

    return image.implementation(ctx, cmd = cmd)

# Attention: We do *not* include the transition that by default is present in
# rules_docker: We transition ourselves when building js_image_layers.
#
# This is consistent with how rules_oci (successor of rules_docker) handles this.
_node_image = rule(
    doc = """Tiny shim around the container_image rule to extract the entry point path""",
    attrs = dicts.add(
        dicts.omit(image.attrs, ["_allowlist_function_transition"]),
        entry_point = attr.label(allow_single_file = True),
    ),
    outputs = image.outputs,
    toolchains = ["@io_bazel_rules_docker//toolchains/docker:toolchain_type"],
    executable = True,
    implementation = _node_image_impl,
)

def node_binary_image(
        name,
        base,
        data,
        entry_point,
        user = "node",
        ports = [],
        volumes = [],
        platform = Label("//private/docker:node_default_platform"),
        visibility = None):
    """Builds a docker image that runs the entry_point script.

    Example: [`@examples//api`](../../examples/api/BUILD.bazel#:~:text=name%20%3D%20%22api%22%2C)

    Args:
      name: name of the target.
      base: docker base image, must contain the node binary.
      data: ts_project(s) that are required for this app.
      entry_point: JS file that is to be run.
        The cmd of the created image will be `node <entry_point>`
      user: User the image runs with (must exist in the base image).
      ports: Ports this image exposes (like EXPOSE in Dockerfile).
      volumes: mount points this image uses (like VOLUME in Dockerfile).
        These should be full paths not names (e.g. `["/data"]`).
        For each of these, a directory owned by `user` is automatically created
        in the image (to allow the node process to actually write to it).
      platform: Platform to build the dependencies that go into the image for.
        Mostly relevant for Prisma engines. Defaults to Debian Linux with OpenSSL 3.x.
      visibility: visibility of the main target.
    """

    js_image_layers(
        name = name,
        data = data,
        platform = platform,
    )

    layers = [
        name + ".node-modules",
        name + ".app",
    ]

    if volumes:
        empty_dir_layer(
            name = name + ".volume_layer",
            base = base,
            user = user,
            paths = volumes,
        )

        layers.insert(0, name + ".volume_layer")

    _node_image(
        name = name,
        base = base,
        layers = layers,
        entry_point = entry_point,
        ports = ports,
        volumes = volumes,
        user = user,
        workdir = "/app",
        visibility = visibility,
    )
