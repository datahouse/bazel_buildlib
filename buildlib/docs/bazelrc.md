<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Rules for bazelrc management.


## Functions

- [bazelrc](#bazelrc)


<a id="bazelrc"></a>

## bazelrc

<pre>
load("@dh_buildlib//bazelrc:defs.bzl", "bazelrc")

bazelrc(<a href="#bazelrc-name">name</a>)
</pre>

Rule to test bazel / bazelisk config is according to Datahouse standards.

Must be in the repository root.

Example: [`@examples//:bazelrc`](../../examples/BUILD.bazel#:~:text=name%20%3D%20%22bazelrc%22%2C)


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="bazelrc-name"></a>name |  Name of the rule, must be "bazelrc".   |  none |


