"""ts_library macro."""

load("@aspect_rules_js//js:libs.bzl", "js_library_lib")
load("@aspect_rules_swc//swc:defs.bzl", "swc")
load("@aspect_rules_ts//ts:defs.bzl", "ts_project")
load("@bazel_skylib//lib:partial.bzl", "partial")
load(":config.bzl", "tsconfig")
load(":eslint.bzl", "eslint")
load(":providers.bzl", "TsLibraryInfo")

def ts_default_srcs():
    """Default glob for `ts_library` / `ts_test` `srcs`.

    Use this when you want to pass additional (typically generated) `srcs` to
    `ts_library` / `ts_test`, but you also want to include all the default sources.

    This is a shorthand for

    ```
    glob(
        include = ["**/*.ts", "**/*.tsx", "**/*.json"],
        exclude = ["**/package.json", "**/package-lock.json", "**/tsconfig*.json"],
    )
    ```

    Example: [`@examples//shared-lib/src`](../../examples/shared-lib/src/BUILD.bazel#:~:text=srcs%20%3D%20ts_default_srcs)
    """

    # Essentially copied from rules_ts
    # https://github.com/aspect-build/rules_ts/blob/9fed0d6adb1094ea095d86d6970ac2fc041b4cae/ts/defs.bzl#L283-L291
    return native.glob(
        include = ["**/*.ts", "**/*.tsx", "**/*.json"],
        exclude = ["**/package.json", "**/package-lock.json", "**/tsconfig*.json"],
    )

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
      srcs: ts, tsx, json sources to compile. Defaults to `ts_default_srcs()`.
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
        srcs = ts_default_srcs()

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
            swcrc = Label(":swcrc"),
        ),
        assets = assets,
        resolve_json_module = True,
        tsconfig = ":tsconfig",
        deps = deps,
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
