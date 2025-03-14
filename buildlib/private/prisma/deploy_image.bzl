"""prisma_deploy_image macro."""

load("@aspect_bazel_lib//lib:tar.bzl", "tar")
load("@rules_oci//oci:defs.bzl", "oci_image")
load("//private/docker:js_image_layers.bzl", "js_image_layers")

def prisma_deploy_image(
        name,
        schema,
        base = "@node_image_linux_amd64",
        platform = Label("//private/docker:node_default_platform"),
        visibility = None,
        testonly = None):
    """EXPERIMENTAL: Generates a docker image for managing production databases using the prisma cli. 

    TODO.

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

    launcher = Label(":image-cli-launcher.sh")

    tar(
        name = name + ".launcher",
        srcs = [schema, launcher],
        mtree = [
            "app/schema.prisma    uid=0 gid=0 time=0 mode=0644 type=file content=$(location %s)" % schema,
            "usr/local/bin/prisma uid=0 gid=0 time=0 mode=0755 type=file content=$(location %s)" % launcher,
        ],
    )

    oci_image(
        name = name,
        base = base,
        tars = [
            name + ".node-modules.tar.gz",
            name + ".app.tar.gz",
            name + ".launcher",
        ],
        cmd = ["prisma"],
        workdir = "/app",
        testonly = testonly,
        visibility = visibility,
    )
