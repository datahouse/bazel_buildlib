<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Rules for language agnostic tooling

Typically they appear in the repository root. They make sure the configs are
in-line with Datahouse standards and consistent with each other.

Also see [examples/BUILD.bazel](../../examples/BUILD.bazel).

<a id="bazelrc"></a>

## bazelrc

<pre>
bazelrc(<a href="#bazelrc-name">name</a>)
</pre>

Rule to test bazel / bazelisk config is according to Datahouse standards.

Must be in the repository root.

Example: [`@examples//:bazelrc`](../../examples/BUILD.bazel#:~:text=name%20%3D%20%22bazelrc%22%2C)


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="bazelrc-name"></a>name |  Name of the rule, must be "bazelrc".   |  none |


<a id="renovate_config"></a>

## renovate_config

<pre>
renovate_config(<a href="#renovate_config-name">name</a>, <a href="#renovate_config-src">src</a>)
</pre>

Checks a renovate config for consistency.

Example: [`@examples//:renovate`](../../examples/BUILD.bazel#:~:text=name%20%3D%20%22renovate%22%2C)


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="renovate_config-name"></a>name |  Rule name. Should be "renovate".   |  none |
| <a id="renovate_config-src"></a>src |  Renovate config (`renovate.json` or `renovate.json5`).   |  none |


