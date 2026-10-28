"""Rules to bundle react apps."""

load("@aspect_rules_js//js:defs.bzl", "js_run_binary")
load("@bazel_lib//lib:copy_file.bzl", "copy_file")
load("@bazel_skylib//lib:paths.bzl", "paths")
load("@rules_oci//oci:defs.bzl", "oci_image")
load("@tar.bzl//tar:mtree.bzl", "mtree_mutate", "mtree_spec")
load("@tar.bzl//tar:tar.bzl", "tar")
load("//private:npm_js_binary.bzl", "npm_js_binary")

def bundle(name, deps, nginx_image, tailwind = False, testonly = None):
    """
    Creates the run / cold image for react_app.

    Args:
      name: Name of the rule.
      deps: Dependencies.
      nginx_image: Nginx image to use.
      tailwind: Whether to add the Tailwind packages.
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

    tailwind_srcs = [
        "//:node_modules/@tailwindcss/vite",
        "//:node_modules/tailwindcss",
    ] if tailwind else []

    js_run_binary(
        name = bundle_name,
        args = [
            "build",
            "--config",
            "%s/vite.config.mjs" % native.package_name(),
            "--outDir",
            bundle_name,
            native.package_name(),
        ],
        tool = name + ".bin",
        srcs = deps + [
            name + ".vite.cfg",
            "//:node_modules/vite",
            "//:node_modules/@vitejs/plugin-react",
        ] + tailwind_srcs,
        include_transitive_sources = True,
        include_types = False,
        include_npm_sources = True,
        silent_on_success = False,  # report bundle sizes
        out_dirs = [bundle_name],
        env = {"DH_BUILDLIB_REACT_APP_TAILWIND": str(int(tailwind))},
        progress_message = "Bundling %{label}",
        testonly = testonly,
    )

    mtree_spec(
        name = name + ".mtree.base",
        srcs = [bundle_name],
        testonly = testonly,
    )

    mtree_mutate(
        name = name + ".mtree.moved",
        mtree = name + ".mtree.base",
        strip_prefix = paths.join(native.package_name(), bundle_name),
        package_dir = "usr/share/nginx/html",
        testonly = testonly,
    )

    tar(
        name = name + ".tar",
        mtree = name + ".mtree.moved",
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
