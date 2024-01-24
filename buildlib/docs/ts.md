<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Typescript compilation and linting rules.

<a id="js_binary"></a>

## js_binary

<pre>
js_binary(<a href="#js_binary-kwargs">kwargs</a>)
</pre>

js_binary rule that transitions its sources to CommonJS modules.

Otherwise equivalent to [js_binary in rules_js](https://github.com/aspect-build/rules_js/blob/main/docs/js_binary.md).
If in doubt, use this over the one in rules_js.

Example: [`@examples//prisma/seed`](../../examples/prisma/seed/BUILD.bazel#:~:text=name%20%3D%20%22seed%22%2C)


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="js_binary-kwargs"></a>kwargs |  Keyword arguments directly forwarded to rules_js' js_binary.   |  none |


<a id="ts_default_srcs"></a>

## ts_default_srcs

<pre>
ts_default_srcs()
</pre>

Default glob for `ts_library` / `ts_test` `srcs`.

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



<a id="ts_library"></a>

## ts_library

<pre>
ts_library(<a href="#ts_library-name">name</a>, <a href="#ts_library-srcs">srcs</a>, <a href="#ts_library-deps">deps</a>, <a href="#ts_library-data">data</a>, <a href="#ts_library-assets">assets</a>, <a href="#ts_library-uses_dom">uses_dom</a>, <a href="#ts_library-visibility">visibility</a>, <a href="#ts_library-testonly">testonly</a>)
</pre>

Typescript library.

Example: [`@examples//shared-lib/src`](../../examples/shared-lib/src/BUILD.bazel#:~:text=name%20%3D%20%22src%22%2C)


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="ts_library-name"></a>name |  name of the rule   |  none |
| <a id="ts_library-srcs"></a>srcs |  ts, tsx, json sources to compile. Defaults to `ts_default_srcs()`.   |  `None` |
| <a id="ts_library-deps"></a>deps |  dependencies (other ts_library or npm dependencies)   |  `[]` |
| <a id="ts_library-data"></a>data |  required runtime data (e.g. csv files)   |  `None` |
| <a id="ts_library-assets"></a>assets |  required imported assets (e.g. css files) - Use `assets` for files you `import` (e.g. import './App.css') - Use `data` for files you read programmatically (e.g. `fs.readFile("data.csv")`)   |  `[]` |
| <a id="ts_library-uses_dom"></a>uses_dom |  Whether this library uses the DOM. Forces uses_dom transitively on dependencies.   |  `False` |
| <a id="ts_library-visibility"></a>visibility |  rule visibility   |  `None` |
| <a id="ts_library-testonly"></a>testonly |  whether this is for tests only (default: false)   |  `None` |


<a id="ts_test"></a>

## ts_test

<pre>
ts_test(<a href="#ts_test-name">name</a>, <a href="#ts_test-srcs">srcs</a>, <a href="#ts_test-deps">deps</a>, <a href="#ts_test-data">data</a>, <a href="#ts_test-uses_dom">uses_dom</a>, <a href="#ts_test-tags">tags</a>)
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
| <a id="ts_test-tags"></a>tags |  tags (propagated to the test rule)   |  `None` |


