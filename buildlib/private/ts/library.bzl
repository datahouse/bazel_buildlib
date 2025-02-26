"""ts_library macro."""

load("@aspect_rules_js//js:libs.bzl", "js_library_lib")
load("@aspect_rules_swc//swc:defs.bzl", "swc")
load("@aspect_rules_ts//ts:defs.bzl", "TsConfigInfo", "ts_project")
load("@bazel_skylib//lib:partial.bzl", "partial")
load(":config.bzl", "tsconfig")
load(":eslint.bzl", "eslint")
load(":providers.bzl", "TsLibraryInfo")

_ts_library_base_providers = js_library_lib.provides + [TsConfigInfo]

def _ts_library_impl(ctx):
    base = [
        ctx.attr.base[provider]
        for provider in _ts_library_base_providers
    ]

    return base + [
        TsLibraryInfo(uses_dom = ctx.attr.uses_dom),
    ]

# TODO: This rule is a hack.
# It requires us to manually list all (relevant) providers returned by ts_project.
# This is brittle and fails whenever rules_ts makes internal changes (e.g. #1121).
# We should replace this rule with something more principled (tracked as #1124).
_ts_library = rule(
    doc = "Glue rule to attach relevant providers",
    implementation = _ts_library_impl,
    attrs = {
        "base": attr.label(
            providers = [_ts_library_base_providers],
        ),
        "uses_dom": attr.bool(),
    },
    provides = [TsLibraryInfo] + _ts_library_base_providers,
)

def ts_library(
        name,
        srcs = None,
        deps = [],
        data = None,
        assets = [],
        uses_dom = False,
        tsc_repository = "@npm_typescript",
        visibility = None,
        testonly = None):
    """Typescript library.

    Example: [`@examples//shared-lib/src`](../../examples/shared-lib/src/BUILD.bazel#:~:text=name%20%3D%20%22src%22%2C)

    Args:
      name: name of the rule
      srcs: ts, tsx sources to compile. Defaults to `glob(["**/*.ts", "**/*.tsx"])`.
      deps: dependencies (other ts_library or npm dependencies)
      assets: required imported assets (e.g. css files)
        - Use `assets` for files you `import` (e.g. import './App.css')
        - Use `data` for files you read programmatically (e.g. `fs.readFile("data.csv")`)
      data: required runtime data (e.g. csv files)
      uses_dom: Whether this library uses the DOM.
        Forces uses_dom transitively on dependencies.
      tsc_repository: which typescript bazel repository to use
        (most likely you will not need this option).
      visibility: rule visibility
      testonly: whether this is for tests only (default: false)
    """

    if srcs == None:
        srcs = native.glob(["**/*.ts", "**/*.tsx"])

    tsconfig(
        name = "tsconfig",
        srcs = srcs,
        deps = deps,
        uses_dom = uses_dom,
        testonly = testonly,
    )

    ts_project(
        name = name + ".tsc",
        srcs = srcs,
        data = data,
        tsc = "%s//:tsc" % tsc_repository,
        tsc_worker = "%s//:tsc_worker" % tsc_repository,
        validator = "%s//:validator" % tsc_repository,
        visibility = visibility,
        testonly = testonly,
        composite = True,
        source_map = True,
        transpiler = partial.make(
            swc,
            swcrc = Label(":.swcrc"),
        ),
        assets = assets,
        tsconfig = ":tsconfig",
        # Note: This deploys the root package.json to the final artifacts.
        # This will almost certainly declare unnecessary dependencies (the root
        # package.json contains the dependencies of the entire repository).
        #
        # These dependencies are neither actually required/used nor provided/copied
        # into the artifact, so it is not really an issue (but it might confuse
        # a downstream tool at some point).
        #
        # Avoiding this would unnecessarily complicate the file layout
        # (especially while preserving IDE support), so for now, we do not do it.
        deps = deps + ["//:package_json"],
    )

    _ts_library(
        name = name,
        base = name + ".tsc",
        uses_dom = uses_dom,
        visibility = visibility,
        testonly = testonly,
    )

    eslint(
        name = name + ".lint",
        srcs = srcs,
        deps = deps,
        testonly = testonly,
    )
