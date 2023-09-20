"""js_binary / js_test rules for node_modules.

Equivalent to js_binary / js_test rules generated with npm_link_packages but
does not require the targets to be present to load the definitions.

This means users are not required to install packages they do not use.

Note that we use the standard js_binary here to avoid unncesessary transitions.
"""

load("@aspect_bazel_lib//lib:directory_path.bzl", "directory_path")
load("@aspect_rules_js//js:defs.bzl", "js_binary", "js_test")
load("@bazel_skylib//rules:select_file.bzl", "select_file")

def _select_entrypoint(name, node_module, entry_point, testonly):
    dep_lbl = "//:node_modules/" + node_module
    entry_point_lbl = name + ".entry_point"

    select_file(
        name = name + ".node_module",
        srcs = dep_lbl,
        subpath = node_module,
        testonly = testonly,
    )

    directory_path(
        name = entry_point_lbl,
        directory = name + ".node_module",
        path = entry_point,
        testonly = testonly,
    )

    return dep_lbl, entry_point_lbl

def npm_js_binary(name, node_module, entry_point, testonly = None, visibility = None):
    dep_lbl, entry_point_lbl = _select_entrypoint(name, node_module, entry_point, testonly)

    js_binary(
        name = name,
        entry_point = entry_point_lbl,
        data = [dep_lbl],
        testonly = testonly,
        visibility = visibility,
    )

def npm_js_test(name, node_module, entry_point, args = [], data = [], tags = None):
    dep_lbl, entry_point_lbl = _select_entrypoint(name, node_module, entry_point, testonly = True)

    js_test(
        name = name,
        entry_point = entry_point_lbl,
        args = args,
        data = [dep_lbl] + data,
        tags = tags,
        testonly = True,
    )
