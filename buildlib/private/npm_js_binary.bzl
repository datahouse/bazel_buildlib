"""js_binary / js_test rules for node_modules.

Equivalent to js_binary / js_test rules generated with npm_link_packages but
does not require the targets to be present to load the definitions.

This means users are not required to install packages they do not use.
"""

load("@aspect_rules_js//js:defs.bzl", "js_binary", "js_test")
load("@aspect_rules_js//js:providers.bzl", "JsInfo")
load("@bazel_lib//lib:directory_path.bzl", "DirectoryPathInfo")

def _entrypoint_impl(ctx):
    # We need to look for the actual node_module store, not the top-level link:
    # Otherwise the pnpm layout does not work (and node will not find any
    # dependencies of the module).
    #
    # A full path looks like this:
    #
    #   node_modules/.aspect_rules_js/jest@29.7.0_at_types_node_22.3.0/node_modules/jest
    #
    # The middle section (jest@29.7.0_at_types_node_22.3.0) identifies the module.
    # However, since it contains the version and relies on name mangling for sub-directories
    # (e.g. @apollo/client maps to .aspect_rules_js/@apollo+client@3.11.4_-907186023/node_modules/@apollo/client),
    # it is tricky to correctly filter on it.
    #
    # Instead we do the following.
    # - Check the path starts with `node_modules/.aspect_rules_js/`.
    #   This ensures the path is an actual store, and not a top level link.
    # - Check the path ends in `/node_modules/<module>`.
    #   This ensure the path is the node module we are interested in *in a store*
    #   (but not necessarily in its own).
    #
    # However, because we know that we are looking at the transitive dependencies
    # of the node module we are interested in, we know only its own store contains
    # a reference to it (lest there are circular dependencies).

    expected_path = "/node_modules/%s" % ctx.attr.node_module_name

    for f in ctx.attr.node_module[JsInfo].npm_sources.to_list():
        if f.short_path.startswith("node_modules/.aspect_rules_js/") and f.short_path.endswith(expected_path):
            return [DirectoryPathInfo(directory = f, path = ctx.attr.entry_point)]

    fail("couldn't find {} in {}".format(expected_path, ctx.attr.node_module.label))

_entrypoint = rule(
    implementation = _entrypoint_impl,
    attrs = {
        "entry_point": attr.string(),
        "node_module": attr.label(providers = [JsInfo]),
        "node_module_name": attr.string(),
    },
)

def _select_entrypoint(name, node_module, entry_point, from_root_workspace, testonly):
    dep_lbl = "//:node_modules/" + node_module

    if from_root_workspace:
        dep_lbl = "@@" + dep_lbl

    entry_point_lbl = name + ".entry_point"

    _entrypoint(
        name = name + ".entry_point",
        node_module = dep_lbl,
        node_module_name = node_module,
        entry_point = entry_point,
        testonly = testonly,
    )

    return dep_lbl, entry_point_lbl

def npm_js_binary(
        name,
        node_module,
        entry_point,
        from_root_workspace = False,
        testonly = None,
        visibility = None):
    dep_lbl, entry_point_lbl = _select_entrypoint(
        name,
        node_module,
        entry_point,
        from_root_workspace,
        testonly,
    )

    js_binary(
        name = name,
        entry_point = entry_point_lbl,
        data = [dep_lbl],
        testonly = testonly,
        visibility = visibility,
    )

def npm_js_test(
        name,
        node_module,
        entry_point,
        data = [],
        **kwargs):
    dep_lbl, entry_point_lbl = _select_entrypoint(
        name,
        node_module,
        entry_point,
        from_root_workspace = False,
        testonly = True,
    )

    js_test(
        name = name,
        entry_point = entry_point_lbl,
        data = [dep_lbl] + data,
        testonly = True,
        **kwargs
    )
