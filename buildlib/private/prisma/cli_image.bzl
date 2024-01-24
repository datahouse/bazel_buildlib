"""prisma_cli_image macro."""

load("@aspect_bazel_lib//lib:tar.bzl", "tar")
load("@bazel_skylib//lib:paths.bzl", "paths")
load("@rules_oci//oci:defs.bzl", "oci_image")
load("//private/docker:js_image_layers.bzl", "js_image_layers")
load(":node_modules_bin_path.bzl", "node_modules_bin_path")

def prisma_cli_image(
        name,
        schema,
        base = "@node_image",
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
        name = name + ".layers",
        data = [
            "//:node_modules/prisma",
        ],
        app_layer = name + ".app.tar.gz",
        node_modules_layer = name + ".node-modules.tar.gz",
        platform = platform,
        testonly = testonly,
    )

    tar(
        name = name + ".schema",
        srcs = [schema],
    )

    workdir = paths.join("/app", native.package_name())

    oci_image(
        name = name,
        base = base,
        tars = [
            name + ".node-modules.tar.gz",
            name + ".app.tar.gz",
            name + ".schema",
        ],
        env = {"PATH": node_modules_bin_path("/app")},
        cmd = ["prisma"],
        workdir = workdir,
        testonly = testonly,
        visibility = visibility,
    )
