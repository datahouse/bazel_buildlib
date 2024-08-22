<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Rules for formatting.


## Functions

- [format](#format)


<a id="format"></a>

## format

<pre>
load("@dh_buildlib//format:defs.bzl", "format")

format(<a href="#format-name">name</a>)
</pre>

Rule to format code.

Example: [`@examples//:format`](../../examples/BUILD.bazel#:~:text=name%20%3D%20%22format%22)

The target must be called `format` and in the root package.

Supported formatters:
- [Prettier](https://prettier.io/)
- [Buildifier](https://github.com/bazelbuild/buildtools/blob/master/buildifier/README.md)

To format:

```sh
bazel run //:format
```

To check formatting:

```sh
bazel run //:format -- --check
```


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="format-name"></a>name |  Name of the genreated rule, must be "format"   |  none |


