"""Rules to bundle react apps."""

load("@aspect_rules_js//js:defs.bzl", "js_run_binary")
load("@bazel_skylib//lib:paths.bzl", "paths")
load("@bazel_skylib//rules:copy_file.bzl", "copy_file")
load("@rules_oci//oci:defs.bzl", "oci_image")
load("//private/tar:tar.bzl", "tar_auto_mtree")
load("//private/ts:npm_js_binary.bzl", "npm_js_binary")

def bundle(name, deps, nginx_image, testonly = None):
    """
    Creates the run / cold image for react_app.

    Args:
      name: Name of the rule.
      deps: Dependencies.
      nginx_image: Nginx image to use.
      testonly: Testonly flag
    """

    npm_js_binary(
        name = name + ".bin",
        node_module = "vite",
        entry_point = "bin/vite.js",
        testonly = testonly,
    )

    copy_file(
        name = name + ".vite.cfg",
        src = Label(":vite.config.mjs"),
        out = "vite.config.mjs",
        testonly = testonly,
    )

    bundle_name = name + ".bundle"

    js_run_binary(
        name = bundle_name,
        args = ["build", "--outDir", bundle_name, native.package_name()],
        tool = name + ".bin",
        srcs = deps + [
            name + ".vite.cfg",
            "//:node_modules/vite",
            "//:node_modules/@vitejs/plugin-react",
        ],
        include_transitive_sources = True,
        include_declarations = False,
        include_npm_sources = True,
        silent_on_success = False,  # report bundle sizes
        out_dirs = [bundle_name],
        progress_message = "Bundling %{label}",
        testonly = testonly,
    )

    tar_auto_mtree(
        name = name + ".tar",
        strip_prefix = paths.join(native.package_name(), bundle_name),
        replace_prefix = "usr/share/nginx/html",
        srcs = [bundle_name],
        testonly = testonly,
    )

    oci_image(
        name = name,
        base = nginx_image,
        tars = [
            Label(":nginx-config-tar"),
            name + ".tar",
        ],
        labels = {"ch.datahouse.ops.overlay-diff-allow-template": "nginx"},
        testonly = testonly,
    )
