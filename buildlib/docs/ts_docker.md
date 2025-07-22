<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Rules for Typescript in/on Docker.


## Macros

- [docker_image_for_ts_test](#docker_image_for_ts_test)
- [node_binary_image](#node_binary_image)


<a id="docker_image_for_ts_test"></a>

## docker_image_for_ts_test

<pre>
load("@dh_buildlib//ts/docker:defs.bzl", "docker_image_for_ts_test")

docker_image_for_ts_test(*, <a href="#docker_image_for_ts_test-name">name</a>, <a href="#docker_image_for_ts_test-image">image</a>, <a href="#docker_image_for_ts_test-visibility">visibility</a>)
</pre>

Prepares a docker image to be loaded in a TS test.

Typically, this is for use with testcontainers.

For example, say you have the following in your BUILD.bazel:

```BUILD
docker_image_for_ts_test(
  name = "load_my_image",
  image = "//path/to/my:image",
)

ts_test(
  name = "test"
  deps = [":load_my_image"],
)
```

Now inside your test, you can:

```ts
import { GenericContainer } from "testcontainers";
import loadMyImage from "./load_my_image.js";

test("my test", async () => {
  // This will load the image into the local docker daemon
  // and return a reference you can use with testcontainers.
  const image = await loadMyImage();

  const container = await new GenericContainer(image).start();
});
```

Note: This rule can only be used for tests.

Example: [`@examples//prisma/test:load_postgres_image`](../../examples/prisma/test/BUILD.bazel#:~:text=name%20%3D%20%22load_postgres_image%22%2C)

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="docker_image_for_ts_test-name"></a>name |  A unique name for this macro instance. Normally, this is also the name for the macro's main or only target. The names of any other targets that this macro might create will be this name with a string suffix.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="docker_image_for_ts_test-image"></a>image |  The docker image to load.   | <a href="https://bazel.build/concepts/labels">Label</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | required |  |
| <a id="docker_image_for_ts_test-visibility"></a>visibility |  The visibility to be passed to this macro's exported targets. It always implicitly includes the location where this macro is instantiated, so this attribute only needs to be explicitly set if you want the macro's targets to be additionally visible somewhere else.   | <a href="https://bazel.build/concepts/labels">List of labels</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  |


<a id="node_binary_image"></a>

## node_binary_image

<pre>
load("@dh_buildlib//ts/docker:defs.bzl", "node_binary_image")

node_binary_image(*, <a href="#node_binary_image-name">name</a>, <a href="#node_binary_image-data">data</a>, <a href="#node_binary_image-base">base</a>, <a href="#node_binary_image-entry_point">entry_point</a>, <a href="#node_binary_image-platform">platform</a>, <a href="#node_binary_image-ports">ports</a>, <a href="#node_binary_image-testonly">testonly</a>, <a href="#node_binary_image-user">user</a>, <a href="#node_binary_image-visibility">visibility</a>,
                  <a href="#node_binary_image-volumes">volumes</a>)
</pre>

Builds a docker image that runs the entry_point script.

Example: [`@examples//api`](../../examples/api/BUILD.bazel#:~:text=name%20%3D%20%22api%22%2C)

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="node_binary_image-name"></a>name |  A unique name for this macro instance. Normally, this is also the name for the macro's main or only target. The names of any other targets that this macro might create will be this name with a string suffix.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="node_binary_image-data"></a>data |  ts_project(s) that are required for this app.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | required |  |
| <a id="node_binary_image-base"></a>base |  docker base image, must contain the node binary. Defaults to: @node_image_linux_amd64   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `None`  |
| <a id="node_binary_image-entry_point"></a>entry_point |  JS file that is to be run. The cmd of the created image will be `node <entry_point>`   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="node_binary_image-platform"></a>platform |  Platform to build the dependencies that go into the image for. Mostly relevant for Prisma engines. Defaults to Debian Linux with OpenSSL 3.x.   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `"@dh_buildlib//private/docker:node_default_platform"`  |
| <a id="node_binary_image-ports"></a>ports |  Ports this image exposes (like EXPOSE in Dockerfile).   | List of strings; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `[]`  |
| <a id="node_binary_image-testonly"></a>testonly |  testonly flag   | Boolean; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `False`  |
| <a id="node_binary_image-user"></a>user |  User the image runs with (must exist in the base image).   | String | optional |  `"node"`  |
| <a id="node_binary_image-visibility"></a>visibility |  The visibility to be passed to this macro's exported targets. It always implicitly includes the location where this macro is instantiated, so this attribute only needs to be explicitly set if you want the macro's targets to be additionally visible somewhere else.   | <a href="https://bazel.build/concepts/labels">List of labels</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  |
| <a id="node_binary_image-volumes"></a>volumes |  mount points this image uses (like VOLUME in Dockerfile). These should be full paths not names (e.g. `["/data"]`). For each of these, a directory owned by `user` is automatically created in the image (to allow the node process to actually write to it).   | List of strings; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `[]`  |


