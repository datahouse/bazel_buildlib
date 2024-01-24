<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Rules to hack around things.

They really shouldn't be here, but we haven't found a better solution.

If you use any of these, expect to be asked to migrate quickly, once a cleaner solution is available.

<a id="transpile_esm_to_cjs"></a>

## transpile_esm_to_cjs

<pre>
transpile_esm_to_cjs(<a href="#transpile_esm_to_cjs-name">name</a>, <a href="#transpile_esm_to_cjs-node_module">node_module</a>, <a href="#transpile_esm_to_cjs-replacements">replacements</a>)
</pre>

Rule to transpile a ESM only npm package to CJS.

Attention: This rule does the bare minimum we need for packages used in example.
If you intend to use it in your project (after thinking twice, of course),
make sure you validate that it actually works for your use case.

Example: [`@examples//:node_modules/graphql-upload-cjs`](../../examples/BUILD.bazel#:~:text=name%20%3D%20%22node_modules/graphql%2Dupload%2Dcjs%22%2C)

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="transpile_esm_to_cjs-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="transpile_esm_to_cjs-node_module"></a>node_module |  npm package to transpile (should be in //:node_modules/*)   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="transpile_esm_to_cjs-replacements"></a>replacements |  replacements for dependencies of node_module (in case they are also ESM only).<br><br>Keys are the replacements (must be created by transpile_esm_to_cjs as well), values are the names of the package to be replaced.   | <a href="https://bazel.build/rules/lib/dict">Dictionary: Label -> String</a> | optional |  `{}`  |


