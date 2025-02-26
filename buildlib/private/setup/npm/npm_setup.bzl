"""npm related setup."""

load("@aspect_rules_js//js:defs.bzl", "js_library", "js_test")
load("//private/setup:write_setup_source_file.bzl", "write_setup_source_file")

# buildifier: disable=unnamed-macro (private)
def npm_setup(update_targets):
    """npm setup

    Args:
      update_targets: tracking of write_source_file targets
        (mutable, only use to pass to write_setup_source_file).
    """

    js_library(
        name = "package_json",
        srcs = ["package.json"],
        visibility = ["//:__subpackages__"],
    )

    js_test(
        name = "package_json_test",
        args = ["./package.json"],
        data = [Label("//private/setup/npm/src"), "package.json"],
        entry_point = Label("//private/setup/npm/src:check-package-json.js"),
    )

    pnpm = Label("@pnpm")
    native.sh_test(
        name = "pnpm_lock_test",
        srcs = [Label(":test-pnpm-lock.sh")],
        env = {
            "PNPM_BIN": "$(rootpath %s)" % pnpm,
            "PNPM_RELPATH": native.package_name(),
        },
        data = [pnpm, "package.json", "pnpm-lock.yaml"],
    )

    write_setup_source_file(
        name = "npmrc",
        in_file = Label(":default.npmrc"),
        out_file = ".npmrc",
        update_targets = update_targets,
    )

    # Convenience alias to `:pnpm`.
    # There is no reason this could not be a target in buildlib, except that it
    # is longer to write (`@dh_buildlib//:pnpm` instead of just `//:pnpm`).
    native.alias(
        name = "pnpm",
        actual = Label(":pnpm"),
    )
