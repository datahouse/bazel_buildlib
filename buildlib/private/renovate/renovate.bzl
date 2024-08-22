"""Rules for renovate"""

load("@aspect_rules_js//js:defs.bzl", "js_run_binary")
load("@aspect_rules_js//npm:repositories.bzl", "LATEST_PNPM_VERSION")
load("@bazel_skylib//lib:paths.bzl", "paths")
load("//private/ts:npm_js_binary.bzl", "npm_js_test")
load("//private/ts:write_source_file_prettier.bzl", "write_source_file_prettier")

def renovate_config(name, src):
    """Checks a renovate config for consistency.

    Example: [`//:renovate`](../../BUILD.bazel#:~:text=name%20%3D%20%22renovate%22%2C)

    Args:
      name: Rule name. Should be "renovate".
      src: Renovate config (`renovate.json` or `renovate.json5`).
    """

    _, ext = paths.split_extension(src)
    updated_filename = name + ".updated" + ext

    js_run_binary(
        name = name + ".updated",
        tool = Label("//private/renovate/src:update-config"),
        srcs = [src],
        args = [
            "--input",
            "$(location %s)" % src,
            "--output",
            updated_filename,
            "--pnpmVersion",
            LATEST_PNPM_VERSION,
        ],
        outs = [updated_filename],
    )

    write_source_file_prettier(
        name = name,
        in_file = name + ".updated",
        out_file = src,
    )

    npm_js_test(
        name = name + ".test",
        node_module = "renovate",
        entry_point = "dist/config-validator.js",
        args = ["--strict", src],
        data = [src],
    )
