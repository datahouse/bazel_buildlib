"""Internal macro for base image of react hot reload image."""

load("@bazel_skylib//lib:paths.bzl", "paths")
load("@rules_oci//oci:defs.bzl", "oci_image")
load("//private/docker:js_image_layers.bzl", "js_image_layers")

def hot_reload_base(name, deps, node_image, node_image_platform, testonly = None):
    js_image_layers(
        name = name + ".layers",
        data = deps + [
            "//:node_modules/@vitejs/plugin-react",
            "//:node_modules/vite",
        ],
        # Note: We do not request an app layer.
        # The files will be hot copied by the docker compose command.
        node_modules_layer = name + ".node-modules.tar.gz",
        platform = node_image_platform,
        testonly = testonly,
    )

    oci_image(
        name = name,
        base = node_image,
        cmd = [
            "/app/node_modules/.bin/vite",
            "--host",
            "--config",
            "/app/vite.config.js",
        ],
        tars = [
            Label(":vite-config-tar"),
            name + ".node-modules.tar.gz",
        ],
        workdir = paths.join("/app/hot", native.package_name()),
        testonly = testonly,
    )
