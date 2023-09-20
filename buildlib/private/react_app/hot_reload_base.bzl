"""Internal macro for base image of react hot reload image."""

load("@bazel_skylib//lib:paths.bzl", "paths")
load("@io_bazel_rules_docker//container:container.bzl", "container_image")
load("//private/docker:js_image_layers.bzl", "js_image_layers")

def hot_reload_base(name, deps, node_image, node_image_platform, testonly = None):
    js_image_layers(
        name = name + ".layers",
        data = deps + [
            "//:node_modules/@vitejs/plugin-react",
            "//:node_modules/vite",
        ],
        platform = node_image_platform,
        testonly = testonly,
    )

    container_image(
        name = name,
        base = node_image,
        cmd = [
            "/app/node_modules/.bin/vite",
            "--host",
            "--config",
            "/app/vite.config.js",
        ],
        directory = "/app",
        ports = ["80"],
        files = [Label(":vite.config.js")],
        layers = [
            # We ignore the app layer created above.
            # The files will be hot copied via docker mount.
            name + ".layers.node-modules",
        ],
        workdir = paths.join("/app/hot", native.package_name()),
        testonly = testonly,
    )
