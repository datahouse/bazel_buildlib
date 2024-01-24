"""Main react_app rule."""

load("@aspect_rules_js//js:defs.bzl", "js_library")
load("@aspect_rules_js//js:libs.bzl", "js_lib_helpers")
load("@aspect_rules_js//js:providers.bzl", "JsInfo")
load("//private/docker:providers.bzl", "HotReloadableInfo")
load(":bundle.bzl", "bundle")
load(":esm_transition.bzl", "esm_transition")
load(":hot_reload_base.bzl", "hot_reload_base")

def _react_app_impl(ctx):
    files = js_lib_helpers.gather_files_from_js_providers(
        ctx.attr.deps,
        include_transitive_sources = True,
        include_declarations = False,
        include_npm_linked_packages = False,
    )

    filtered_files = depset([
        file
        for file in files.to_list()
        if "/node_modules/" not in file.path
    ])

    return [
        DefaultInfo(files = depset([ctx.file.run_image])),
        HotReloadableInfo(
            files = filtered_files,
            container_path = "/app/hot",
            oci_image = ctx.file.dev_image,
        ),
    ]

_react_app = rule(
    doc = """Glue rule to merge run (cold) and dev (hot) image.""",
    implementation = _react_app_impl,
    attrs = {
        "deps": attr.label_list(
            providers = [JsInfo],
            cfg = esm_transition,
        ),
        "dev_image": attr.label(allow_single_file = True),
        "run_image": attr.label(allow_single_file = True),
        "_allowlist_function_transition": attr.label(
            default = "@bazel_tools//tools/allowlists/function_transition_allowlist",
        ),
    },
)

def react_app(
        name,
        srcs = [],
        deps = [],
        nginx_image = "@nginx_image",
        node_image = "@node_image",
        node_image_platform = Label("//private/docker:node_default_platform"),
        visibility = None,
        testonly = None):
    """Bundles a react app into a hot-reloadable docker image.

    When built normally, the resulting image is simply a static nginx server
    with the bundled react application (aka run or cold image).

    When used with hot reloading (under ibazel), the resulting image will run a dev
    server to provide hot reloading to the browser (aka dev or hot image).

    Example: [`@examples//frontend`](../../examples/frontend/BUILD.bazel#:~:text=name%20%3D%20%22frontend%22%2C)

    Args:
      name: Name of the rule.
      srcs: Direct sources. Typically `index.html`.
      deps: Dependencies. Typically a `src` rule with JS code and an (optional)
          `public` rule with static assets (like favicons).
      nginx_image: Nginx base image to use for the run / cold image.
      node_image: Node base image to use for the dev / hot image.
      node_image_platform: Platform for the node base image (for dev / hot).
      visibility: Rule visibility.
      testonly: Testonly flag.
    """

    js_library(
        name = name + ".lib",
        srcs = srcs,
        deps = deps,
        testonly = testonly,
    )

    bundle(
        name = name + ".run",
        deps = [name + ".lib"],
        nginx_image = nginx_image,
        testonly = testonly,
    )

    hot_reload_base(
        name = name + ".dev",
        deps = [name + ".lib"],
        node_image = node_image,
        node_image_platform = node_image_platform,
        testonly = testonly,
    )

    _react_app(
        name = name,
        run_image = name + ".run",
        dev_image = name + ".dev",
        visibility = visibility,
        deps = [name + ".lib"],
        testonly = testonly,
    )
