<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Typescript compilation and linting rules.


## Functions

- [json_to_ts](#json_to_ts)
- [ts_library](#ts_library)
- [ts_test](#ts_test)


<a id="json_to_ts"></a>

## json_to_ts

<pre>
load("@dh_buildlib//ts:defs.bzl", "json_to_ts")

json_to_ts(<a href="#json_to_ts-name">name</a>, <a href="#json_to_ts-src">src</a>, <a href="#json_to_ts-out">out</a>, <a href="#json_to_ts-type">type</a>, <a href="#json_to_ts-type_imports">type_imports</a>, <a href="#json_to_ts-visibility">visibility</a>, <a href="#json_to_ts-testonly">testonly</a>)
</pre>

Convert JSON to Typescript.

Produces a typescript file with a single default export containing the JSON data.

Example: [`@buildlib//private/ts/test:data`](../private/ts/test/BUILD.bazel#:~:text=name%20%3D%20%22data%22%2C)


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="json_to_ts-name"></a>name |  Name of the resulting rule.   |  none |
| <a id="json_to_ts-src"></a>src |  JSON file to convert to typescript (must end in .json)   |  none |
| <a id="json_to_ts-out"></a>out |  Output file name (defaults to src with .ts extension).   |  `None` |
| <a id="json_to_ts-type"></a>type |  Optional type annotation for the type (e.g. `string`).   |  `None` |
| <a id="json_to_ts-type_imports"></a>type_imports |  Optional import line(s) for the type (e.g. `import type { X } from "./x.js";`).   |  `[]` |
| <a id="json_to_ts-visibility"></a>visibility |  Visibility specifier.   |  `None` |
| <a id="json_to_ts-testonly"></a>testonly |  testonly flag.   |  `None` |


<a id="ts_library"></a>

## ts_library

<pre>
load("@dh_buildlib//ts:defs.bzl", "ts_library")

ts_library(<a href="#ts_library-name">name</a>, <a href="#ts_library-srcs">srcs</a>, <a href="#ts_library-deps">deps</a>, <a href="#ts_library-data">data</a>, <a href="#ts_library-assets">assets</a>, <a href="#ts_library-uses_dom">uses_dom</a>, <a href="#ts_library-tsc_repository">tsc_repository</a>, <a href="#ts_library-visibility">visibility</a>, <a href="#ts_library-testonly">testonly</a>)
</pre>

Typescript library.

Example: [`@examples//shared-lib/src`](../../examples/shared-lib/src/BUILD.bazel#:~:text=name%20%3D%20%22src%22%2C)


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="ts_library-name"></a>name |  name of the rule   |  none |
| <a id="ts_library-srcs"></a>srcs |  ts, tsx sources to compile. Defaults to `glob(["**/*.ts", "**/*.tsx"])`.   |  `None` |
| <a id="ts_library-deps"></a>deps |  dependencies (other ts_library or npm dependencies)   |  `[]` |
| <a id="ts_library-data"></a>data |  required runtime data (e.g. csv files)   |  `None` |
| <a id="ts_library-assets"></a>assets |  required imported assets (e.g. css files) - Use `assets` for files you `import` (e.g. import './App.css') - Use `data` for files you read programmatically (e.g. `fs.readFile("data.csv")`)   |  `[]` |
| <a id="ts_library-uses_dom"></a>uses_dom |  Whether this library uses the DOM. Forces uses_dom transitively on dependencies.   |  `False` |
| <a id="ts_library-tsc_repository"></a>tsc_repository |  which typescript bazel repository to use (most likely you will not need this option).   |  `"@npm_typescript"` |
| <a id="ts_library-visibility"></a>visibility |  rule visibility   |  `None` |
| <a id="ts_library-testonly"></a>testonly |  whether this is for tests only (default: false)   |  `None` |


<a id="ts_test"></a>

## ts_test

<pre>
load("@dh_buildlib//ts:defs.bzl", "ts_test")

ts_test(<a href="#ts_test-name">name</a>, <a href="#ts_test-srcs">srcs</a>, <a href="#ts_test-deps">deps</a>, <a href="#ts_test-data">data</a>, <a href="#ts_test-uses_dom">uses_dom</a>, <a href="#ts_test-env">env</a>, <a href="#ts_test-tags">tags</a>, <a href="#ts_test-tsc_repository">tsc_repository</a>)
</pre>

Typescript test (run with jest)

Example: [`@examples//shared-lib/test`](../../examples/shared-lib/test/BUILD.bazel#:~:text=name%20%3D%20%22test%22%2C)


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="ts_test-name"></a>name |  name of the rule   |  none |
| <a id="ts_test-srcs"></a>srcs |  tests to compile and run. Defaults to `ts_default_srcs()`.   |  `None` |
| <a id="ts_test-deps"></a>deps |  dependencies (other ts_library or npm dependencies)   |  `[]` |
| <a id="ts_test-data"></a>data |  required runtime data (e.g. csv files)   |  `[]` |
| <a id="ts_test-uses_dom"></a>uses_dom |  Whether the tests (or the code under test) requires a DOM.   |  `False` |
| <a id="ts_test-env"></a>env |  Additional environment variables to be made available in the test (subject to `$(location)` and make variable expansion).   |  `None` |
| <a id="ts_test-tags"></a>tags |  tags (propagated to the test rule)   |  `None` |
| <a id="ts_test-tsc_repository"></a>tsc_repository |  which typescript bazel repository to use (most likely you will not need this option).   |  `"@npm_typescript"` |


