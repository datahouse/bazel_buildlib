<!-- Generated with Stardoc: http://skydoc.bazel.build -->

The core, required setup macro.

<a id="buildlib_setup"></a>

## buildlib_setup

<pre>
load("@dh_buildlib//setup/defs:buildlib_setup.bzl", "buildlib_setup")

buildlib_setup(<a href="#buildlib_setup-name">name</a>, <a href="#buildlib_setup-enable_ts">enable_ts</a>)
</pre>

Set-up a dh_buildlib workspace.

- Provides `//:format` / `//:format.test`.
- Validates various configurations for consistency.
- Adds targets required by other dh_buildlib rules
  (e.g. `package_json` for `ts_library`).

Use of this macro is required. dh_buildlib will not work without it.

Note: Adding additional config consistency checks to this rule is explicitly
**not** considered a breaking change (because they surface latent bugs in
the usage configuration).

Example: [`@examples//:buildlib_setup`](../../examples/BUILD.bazel#:~:text=name%20%3D%20%22buildlib_setup%22%2C)


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="buildlib_setup-name"></a>name |  Dummy name argument for tooling. Must be `buildlib_setup`.   |  none |
| <a id="buildlib_setup-enable_ts"></a>enable_ts |  Whether to enable TypeScript support   |  `False` |


