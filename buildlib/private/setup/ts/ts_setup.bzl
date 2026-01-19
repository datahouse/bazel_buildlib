"""TS related setup."""

load("@aspect_rules_js//js:defs.bzl", "js_library", "js_test")
load("@aspect_rules_ts//ts:defs.bzl", "ts_config")
load("@bazel_skylib//rules:copy_file.bzl", "copy_file")
load("//private:prettier_format.bzl", "prettier_format")
load("//private/setup:write_setup_source_file.bzl", "write_setup_source_file")
load("//private/setup/ts:tsconfig_base.bzl", "tsconfig_base")

# buildifier: disable=unnamed-macro (private)
def ts_setup(update_targets):
    """TS setup.

    Args:
      update_targets: tracking of write_source_file targets
        (mutable, only use to pass to write_setup_source_file).
    """

    _tsconfig_base(update_targets)

    _eslint_config_setup(
        name = "eslint_config",
        eslint_config = "eslint.config.js",
        pkg_json = "package.json",
        visibility = ["//:__subpackages__"],
    )

def _eslint_config_setup_impl(name, visibility, eslint_config, pkg_json):
    # We copy the eslint defaults twice.
    # - Once to the source directory, so the IDEs find it.
    # - Once to a nested directory bazel-bin, so eslint finds it when running
    #   under bazel (in the source directory). This is somewhat of a hack.
    #
    # Lastly, we carefully chose the dependency tree, so that the file for the IDEs
    # is copied whenever we lint anything (so it doesn't need to be built explicitly).

    copy_file(
        name = name + "_defaults",
        src = Label(":eslint.dh-defaults.js"),
        out = "dhDefaults.eslint.config.js",
    )

    copy_file(
        name = name + "_defaults_bin",
        src = name + "_defaults",
        out = "bazel-bin/dhDefaults.eslint.config.js",
    )

    js_library(
        name = name,
        srcs = [
            eslint_config,
            name + "_defaults_bin",
            # Add package.json.
            #
            # eslint-plugin-import (transitive dependency of AirBnB) requires the
            # package.json to find the package root:
            # https://github.com/import-js/eslint-plugin-import/blob/d1602854ea9842082f48c51da869f3e3b70d1ef9/src/core/packagePath.js#L11
            #
            # Otherwise, `pkgUp` returns `null`, making the call to `basename` fail.
            pkg_json,
            ":tsconfig-base",
        ],
        visibility = visibility,
    )

    js_test(
        name = name + "_test",
        args = ["$(rootpath %s)" % eslint_config],
        data = [
            Label("//private/setup/ts/src"),
            eslint_config,
        ],
        entry_point = Label("//private/setup/ts/src:check-eslint-config.js"),
    )

_eslint_config_setup = macro(
    attrs = {
        "eslint_config": attr.label(
            mandatory = True,
            allow_single_file = True,
            configurable = False,
        ),
        "pkg_json": attr.label(
            mandatory = True,
            allow_single_file = True,
            configurable = False,
        ),
    },
    implementation = _eslint_config_setup_impl,
)

def _gen_tsconfig_base_impl(ctx):
    # See [evil-bazel-hackery] in buildlib/private/ts/config.bzl
    # for why this is not predeclared in the attrs.
    out = ctx.actions.declare_file("tsconfig-base.json")

    ctx.actions.write(
        content = json.encode(tsconfig_base),
        output = out,
    )

    return DefaultInfo(files = depset([out]))

_gen_tsconfig_base = rule(
    attrs = {},
    implementation = _gen_tsconfig_base_impl,
)

def _tsconfig_base(update_targets):
    _gen_tsconfig_base(
        name = "tsconfig-base.gen",
    )

    ts_config(
        name = "tsconfig-base",
        src = ":tsconfig-base.gen",
        visibility = [
            "//:__subpackages__",
            # Macro friends.
            "@dh_buildlib//private/prisma/generators:__subpackages__",
            "@dh_buildlib//private/setup/ts:__subpackages__",
        ],
    )

    prettier_format(
        name = "tsconfig-base.format",
        src = "tsconfig-base.gen",
        out = "tsconfig-base.fmt.json",
    )

    write_setup_source_file(
        name = "tsconfig-base.write",
        in_file = "tsconfig-base.fmt.json",
        out_file = "tsconfig-base.json",
        update_targets = update_targets,
    )
