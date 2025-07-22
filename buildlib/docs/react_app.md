<!-- Generated with Stardoc: http://skydoc.bazel.build -->

React App rules.

Also see [examples/frontend/BUILD.bazel](../../examples/frontend/BUILD.bazel).

<a id="react_app"></a>

## react_app

<pre>
load("@dh_buildlib//react_app:defs.bzl", "react_app")

react_app(*, <a href="#react_app-name">name</a>, <a href="#react_app-deps">deps</a>, <a href="#react_app-srcs">srcs</a>, <a href="#react_app-nginx_image">nginx_image</a>, <a href="#react_app-node_image">node_image</a>, <a href="#react_app-node_image_platform">node_image_platform</a>, <a href="#react_app-testonly">testonly</a>, <a href="#react_app-visibility">visibility</a>)
</pre>

Bundles a react single page app into a hot-reloadable docker image.

When built normally, the resulting image is simply a static nginx server
with the bundled react application (aka run or cold image).

When used with hot reloading (under ibazel), the resulting image will run a dev
server to provide hot reloading to the browser (aka dev or hot image).

This rule is deliberately opinionated. Notably, it configures both base
images provided (and attempts to keep the behavior of the configs consistent,
in case it isn't, please file a bug).

Per consequence, the base image parameters solely exist so different image
versions can be used in the same project / workspace. Non-default configuration
injected into the base image may be broken in a minor version without prior notice.

Example: [`@examples//frontend`](../../examples/frontend/BUILD.bazel#:~:text=name%20%3D%20%22frontend%22%2C)

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="react_app-name"></a>name |  A unique name for this macro instance. Normally, this is also the name for the macro's main or only target. The names of any other targets that this macro might create will be this name with a string suffix.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="react_app-deps"></a>deps |  Dependencies. Typically a `src` rule with JS code and an (optional) `public` rule with static assets (like favicons).   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="react_app-srcs"></a>srcs |  Direct sources. Typically `index.html`.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="react_app-nginx_image"></a>nginx_image |  Nginx base image to use for the run / cold image. Default: @nginx_image_linux_amd64   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `None`  |
| <a id="react_app-node_image"></a>node_image |  Node base image to use for the dev / hot image. Default: @node_image_linux_amd64   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `None`  |
| <a id="react_app-node_image_platform"></a>node_image_platform |  Platform for the node base image (for dev / hot).   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `"@dh_buildlib//private/docker:node_default_platform"`  |
| <a id="react_app-testonly"></a>testonly |  Testonly flag.   | Boolean; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `False`  |
| <a id="react_app-visibility"></a>visibility |  The visibility to be passed to this macro's exported targets. It always implicitly includes the location where this macro is instantiated, so this attribute only needs to be explicitly set if you want the macro's targets to be additionally visible somewhere else.   | <a href="https://bazel.build/concepts/labels">List of labels</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  |


