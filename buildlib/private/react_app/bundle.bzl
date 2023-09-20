"""Rules to bundle react apps."""

load("@aspect_bazel_lib//lib:copy_file.bzl", "copy_file_action")
load("@aspect_rules_js//js:libs.bzl", "js_lib_helpers")
load("@aspect_rules_js//js:providers.bzl", "JsInfo")
load("@io_bazel_rules_docker//container:container.bzl", "container_image")
load("//private/ts:npm_js_binary.bzl", "npm_js_binary")
load(":esm_transition.bzl", "esm_transition")

def _bundle_impl(ctx):
    vite_cfg = ctx.actions.declare_file("vite.config.js")
    copy_file_action(ctx, ctx.file._vite_config, vite_cfg)

    out_dir = ctx.actions.declare_directory(ctx.label.name)

    inputs = depset(
        direct = [vite_cfg],
        transitive = [
            js_lib_helpers.gather_files_from_js_providers(
                ctx.attr.deps,
                include_transitive_sources = True,
                include_declarations = False,
                include_npm_linked_packages = True,
            ),
        ],
    )

    ctx.actions.run(
        inputs = inputs.to_list(),
        outputs = [out_dir],
        arguments = ["build", "--outDir", ctx.label.name, ctx.label.package],
        executable = ctx.executable.vite,
        progress_message = "Bundling %{label}",
        env = {
            "BAZEL_BINDIR": ctx.bin_dir.path,
        },
    )

    return [DefaultInfo(files = depset([out_dir]))]

_bundle = rule(
    implementation = _bundle_impl,
    attrs = {
        "deps": attr.label_list(providers = [JsInfo]),
        "vite": attr.label(
            executable = True,
            cfg = "exec",
        ),
        "_allowlist_function_transition": attr.label(
            default = "@bazel_tools//tools/allowlists/function_transition_allowlist",
        ),
        "_vite_config": attr.label(
            allow_single_file = [".js"],
            default = Label("//private/react_app:vite.config.js"),
        ),
    },
    # Bundling requires (or works better with) ES modules
    # (rather than CommonJS modules).
    #
    # Techincally, this should be an outbound edge transition on `deps`.
    # However, if we do this, the bindir handling inside the rules becomes more
    # complicated (since the bindir of the rule is not the same anymore than the
    # one of the transitioned dependencies).
    #
    # Therefore, we transition on the inbound edge. Since this rule itself is not
    # configurable by the module type, it doesn't matter.
    cfg = esm_transition,
)

def bundle(name, deps, nginx_image, testonly = None):
    npm_js_binary(
        name = name + ".bin",
        node_module = "vite",
        entry_point = "bin/vite.js",
        testonly = testonly,
    )

    _bundle(
        name = name + ".bundle",
        testonly = testonly,
        deps = deps + [
            "//:node_modules/vite",
            "//:node_modules/@vitejs/plugin-react",
        ],
        vite = name + ".bin",
    )

    container_image(
        name = name,
        base = nginx_image,
        data_path = "./{}.bundle".format(name),
        directory = "/usr/share/nginx/html",
        files = [name + ".bundle"],
        testonly = testonly,
    )
