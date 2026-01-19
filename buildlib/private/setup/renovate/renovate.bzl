"""Renovate setup."""

load("@aspect_rules_js//js:defs.bzl", "js_run_binary")
load("@bazel_lib//lib:utils.bzl", "utils")
load("@rules_nodejs//nodejs:repositories.bzl", "LATEST_KNOWN_NODE_VERSION")
load("//private:npm_js_binary.bzl", "npm_js_test")
load("//private:prettier_format.bzl", "prettier_format")
load("//private/setup:write_setup_source_file.bzl", "write_setup_source_file")

# buildifier: disable=unnamed-macro (private)
def renovate_setup(update_targets):
    """Renovate setup rule.

    Args:
      update_targets: tracking of write_source_file targets
        (mutable, only use to pass to write_setup_source_file).
    """

    has_json = utils.file_exists("renovate.json")
    has_json5 = utils.file_exists("renovate.json5")

    if has_json5 and has_json:
        fail("found both renovate.json and renovate.json5, please remove one")

    if not has_json5 and not has_json:
        return

    ext = "json5" if has_json5 else "json"
    src = "renovate.%s" % ext
    updated_filename = "renovate.updated.%s" % ext
    formatted_filename = "renovate.fmt.%s" % ext

    pnpm_version_file = Label("@dh_buildlib_private_npm//:pnpm/resolved.json")
    js_run_binary(
        name = "renovate.updated",
        tool = Label("//private/setup/renovate/src:update-config"),
        srcs = [
            src,
            pnpm_version_file,
        ],
        # Do not execute in the bindir, work like a "normal" bazel build step.
        copy_srcs_to_bin = False,
        env = {"BAZEL_BINDIR": "."},
        use_execroot_entry_point = False,
        args = [
            "--input",
            "$(location %s)" % src,
            "--output",
            "$@",
            "--pnpmVersionFile",
            "$(execpath %s)" % pnpm_version_file,
            "--latestNodeVersion",
            LATEST_KNOWN_NODE_VERSION,
        ],
        outs = [updated_filename],
    )

    prettier_format(
        name = "renovate.fmt",
        src = updated_filename,
        out = formatted_filename,
    )

    write_setup_source_file(
        name = "renovate.write",
        in_file = formatted_filename,
        out_file = src,
        update_targets = update_targets,
    )

    npm_js_test(
        name = "renovate.test",
        node_module = "renovate",
        entry_point = "dist/config-validator.js",
        args = ["--strict", src],
        data = [src],
    )
