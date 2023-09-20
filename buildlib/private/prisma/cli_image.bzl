"""prisma_cli_image macro."""

load("@bazel_skylib//lib:paths.bzl", "paths")
load("@io_bazel_rules_docker//container:container.bzl", "container_image")
load("//private/docker:js_image_layers.bzl", "js_image_layers")
load(":node_modules_bin_path.bzl", "node_modules_bin_path")

def prisma_cli_image(
        name,
        schema,
        base = "@node_image//image",
        platform = Label("//private/docker:node_default_platform"),
        visibility = None,
        testonly = None):
    """Generates a docker image for executing the prisma cli.

    Example: [`@examples//prisma:cli`](../../examples/prisma/BUILD.bazel#:~:text=name%20%3D%20%22cli%22%2C)

    Args:
      name: name of the rule.
      schema: prisma schema to use.
      base: base image to use
      platform: Platform of the base image.
      visibility: visibility of the rule
      testonly: testonly flag for all targets.
    """

    js_image_layers(
        name,
        data = [
            "//:node_modules/prisma",
        ],
        platform = platform,
        testonly = testonly,
    )

    workdir = paths.join("/app", native.package_name())

    container_image(
        name = name,
        base = base,
        layers = [
            name + ".node-modules",
            name + ".app",
        ],
        directory = workdir,
        files = [schema],
        env = {"PATH": node_modules_bin_path("/app")},
        cmd = ["prisma"],
        workdir = workdir,
        testonly = testonly,
        visibility = visibility,
    )
