"""ts_library macro."""

load("@aspect_rules_js//js:libs.bzl", "js_library_lib")
load("@aspect_rules_swc//swc:defs.bzl", "swc")
load("@aspect_rules_ts//ts:defs.bzl", "ts_project")
load("@bazel_skylib//lib:partial.bzl", "partial")
load(":config.bzl", "tsconfig")
load(":eslint.bzl", "eslint")
load(":providers.bzl", "TsLibraryInfo")

def _ts_library_impl(ctx):
    base = [
        ctx.attr.base[provider]
        for provider in js_library_lib.provides
    ]

    return base + [
        TsLibraryInfo(uses_dom = ctx.attr.uses_dom),
    ]

_ts_library = rule(
    doc = "Glue rule to attach relevant providers",
    implementation = _ts_library_impl,
    attrs = {
        "base": attr.label(
            providers = [js_library_lib.provides],
        ),
        "uses_dom": attr.bool(),
    },
    provides = [TsLibraryInfo] + js_library_lib.provides,
)

def ts_library(
        name,
        srcs = None,
        deps = [],
        data = None,
        assets = [],
        uses_dom = False,
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
