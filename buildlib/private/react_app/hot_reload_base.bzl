"""Internal macro for base image of react hot reload image."""

load("@bazel_skylib//lib:paths.bzl", "paths")
load("@rules_oci//oci:defs.bzl", "oci_image")
load("//private/docker/build:js_image_layers.bzl", "js_image_layers")

def hot_reload_base(name, deps, node_image, node_image_platform, tailwind = False, testonly = None):
    tailwind_data = [
        "//:node_modules/@tailwindcss/vite",
        "//:node_modules/tailwindcss",
    ] if tailwind else []

    js_image_layers(
        name = name + ".layers",
        data = deps + [
            "//:node_modules/@vitejs/plugin-react",
            "//:node_modules/vite",
        ] + tailwind_data,
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
            "node",
            "/app/node_modules/vite/bin/vite.js",
            "--host",
            "--config",
            "/app/vite.config.mjs",
        ],
        tars = [
            Label(":vite-config-tar"),
            name + ".node-modules.tar.gz",
        ],
        workdir = paths.join("/app/hot", native.package_name()),
        env = {"DH_BUILDLIB_REACT_APP_TAILWIND": str(int(tailwind))},
        testonly = testonly,
    )
