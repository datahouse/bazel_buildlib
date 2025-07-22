"""ts_library macro."""

load("@aspect_rules_swc//swc:defs.bzl", "swc")
load("@aspect_rules_ts//ts:defs.bzl", "ts_project")
load("@bazel_skylib//lib:partial.bzl", "partial")
load(":config.bzl", "tsconfig")
load(":eslint.bzl", "eslint")

def ts_library(
        name,
        srcs,
        deps = [],
        data = None,
        assets = [],
        uses_dom = False,
        tsc_repository = "@npm_typescript",
        tags = [],
        visibility = None,
        testonly = None):
    """Typescript library.

    Example: [`@examples//shared-lib/src`](../../examples/shared-lib/src/BUILD.bazel#:~:text=name%20%3D%20%22src%22%2C)

    Args:
      name: name of the rule
      srcs: ts, tsx sources to compile. Typically a glob: `glob(["**/*.ts", "**/*.tsx"])`.
      deps: dependencies (other ts_library or npm dependencies)
      assets: required imported assets (e.g. css files)
        - Use `assets` for files you `import` (e.g. import './App.css')
        - Use `data` for files you read programmatically (e.g. `fs.readFile("data.csv")`)
      data: required runtime data (e.g. csv files)
      uses_dom: Whether this library uses the DOM.
        Forces uses_dom transitively on dependencies.
      tsc_repository: which typescript bazel repository to use
        (most likely you will not need this option).
      tags: tags, propagated to all targets
      visibility: rule visibility
      testonly: whether this is for tests only (default: false)
    """

    tsconfig(
        name = "tsconfig",
        srcs = srcs,
        deps = deps,
        uses_dom = uses_dom,
        tags = tags,
        testonly = testonly,
    )

    ts_project(
        name = name,
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
            source_maps = True,
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
        tags = tags,
    )

    eslint(
        name = name + ".lint",
        srcs = srcs,
        deps = deps,
        tags = tags,
        testonly = testonly,
    )
