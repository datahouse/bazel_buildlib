<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Rules to help with Renovate configuration


## Functions

- [renovate_config](#renovate_config)


<a id="renovate_config"></a>

## renovate_config

<pre>
load("@dh_buildlib//renovate:defs.bzl", "renovate_config")

renovate_config(<a href="#renovate_config-name">name</a>, <a href="#renovate_config-src">src</a>)
</pre>

Checks a renovate config for consistency.

Example: [`//:renovate`](../../BUILD.bazel#:~:text=name%20%3D%20%22renovate%22%2C)


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="renovate_config-name"></a>name |  Rule name. Should be "renovate".   |  none |
| <a id="renovate_config-src"></a>src |  Renovate config (`renovate.json` or `renovate.json5`).   |  none |


