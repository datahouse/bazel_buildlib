<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Concenience rules / macro to ease use of Aspect Bazel Lib's tar / mtree_spec.

<a id="mtree_replace_prefix"></a>

## mtree_replace_prefix

<pre>
mtree_replace_prefix(<a href="#mtree_replace_prefix-name">name</a>, <a href="#mtree_replace_prefix-src">src</a>, <a href="#mtree_replace_prefix-out">out</a>, <a href="#mtree_replace_prefix-prefix">prefix</a>, <a href="#mtree_replace_prefix-replacement">replacement</a>)
</pre>

Modifies target paths in an mtree spec.

For entries that start with `prefix`: Removes and (optionally) replaces the prefix.
Drops entries that do not start with `prefix`.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="mtree_replace_prefix-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="mtree_replace_prefix-src"></a>src |  The mtree file to transform   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="mtree_replace_prefix-out"></a>out |  The transformed mtree file   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  |
| <a id="mtree_replace_prefix-prefix"></a>prefix |  The prefix to remove   | String | required |  |
| <a id="mtree_replace_prefix-replacement"></a>replacement |  Replacement for the prefix   | String | optional |  `""`  |


<a id="mtree_spec"></a>

## mtree_spec

<pre>
mtree_spec(<a href="#mtree_spec-name">name</a>, <a href="#mtree_spec-srcs">srcs</a>, <a href="#mtree_spec-strip_prefix">strip_prefix</a>, <a href="#mtree_spec-replace_prefix">replace_prefix</a>, <a href="#mtree_spec-out">out</a>, <a href="#mtree_spec-visibility">visibility</a>, <a href="#mtree_spec-testonly">testonly</a>)
</pre>

Convenience macro to invoke mtree_spec with strip_refix functionality.

Strictly equivalent to calling aspect_bazel_lib's mtree_spec followed by `mtree_replace_prefix`.


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="mtree_spec-name"></a>name |  Name of the final target.   |  none |
| <a id="mtree_spec-srcs"></a>srcs |  Sources to include in the mtree.   |  none |
| <a id="mtree_spec-strip_prefix"></a>strip_prefix |  `prefix` argument to mtree_replace_prefix.   |  `None` |
| <a id="mtree_spec-replace_prefix"></a>replace_prefix |  `replacement` argument to mtree_replace_prefix.   |  `None` |
| <a id="mtree_spec-out"></a>out |  Output file.   |  `None` |
| <a id="mtree_spec-visibility"></a>visibility |  Visibility specifier.   |  `None` |
| <a id="mtree_spec-testonly"></a>testonly |  Testonly flag.   |  `None` |


<a id="tar_auto_mtree"></a>

## tar_auto_mtree

<pre>
tar_auto_mtree(<a href="#tar_auto_mtree-name">name</a>, <a href="#tar_auto_mtree-srcs">srcs</a>, <a href="#tar_auto_mtree-args">args</a>, <a href="#tar_auto_mtree-compress">compress</a>, <a href="#tar_auto_mtree-strip_prefix">strip_prefix</a>, <a href="#tar_auto_mtree-replace_prefix">replace_prefix</a>, <a href="#tar_auto_mtree-out">out</a>, <a href="#tar_auto_mtree-visibility">visibility</a>, <a href="#tar_auto_mtree-testonly">testonly</a>)
</pre>

Convenience macro to invoke tar with auto mtree with strip_refix functionality.

Strictly equivalent to calling (dh_buildlib) mtree_spec follwed by aspect_bazel_lib's tar.


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="tar_auto_mtree-name"></a>name |  Name of the final target.   |  none |
| <a id="tar_auto_mtree-srcs"></a>srcs |  Sources to include in the tar.   |  none |
| <a id="tar_auto_mtree-args"></a>args |  Passed to tar.   |  `[]` |
| <a id="tar_auto_mtree-compress"></a>compress |  Passed to tar.   |  `None` |
| <a id="tar_auto_mtree-strip_prefix"></a>strip_prefix |  `prefix` argument to mtree_replace_prefix.   |  `None` |
| <a id="tar_auto_mtree-replace_prefix"></a>replace_prefix |  `replacement` argument to mtree_replace_prefix.   |  `None` |
| <a id="tar_auto_mtree-out"></a>out |  Output file.   |  `None` |
| <a id="tar_auto_mtree-visibility"></a>visibility |  Visibility specifier.   |  `None` |
| <a id="tar_auto_mtree-testonly"></a>testonly |  Testonly flag.   |  `None` |


