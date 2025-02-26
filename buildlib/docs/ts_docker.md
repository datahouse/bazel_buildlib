<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Rules for Typescript in/on Docker.


## Functions

- [docker_image_for_ts_test](#docker_image_for_ts_test)
- [node_binary_image](#node_binary_image)


<a id="docker_image_for_ts_test"></a>

## docker_image_for_ts_test

<pre>
load("@dh_buildlib//ts/docker:defs.bzl", "docker_image_for_ts_test")

docker_image_for_ts_test(<a href="#docker_image_for_ts_test-name">name</a>, <a href="#docker_image_for_ts_test-image">image</a>, <a href="#docker_image_for_ts_test-visibility">visibility</a>)
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


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="docker_image_for_ts_test-name"></a>name |  Name of the rule and the generated JS file.   |  none |
| <a id="docker_image_for_ts_test-image"></a>image |  The docker image to load.   |  none |
| <a id="docker_image_for_ts_test-visibility"></a>visibility |  Visibility specification.   |  `None` |


<a id="node_binary_image"></a>

## node_binary_image

<pre>
load("@dh_buildlib//ts/docker:defs.bzl", "node_binary_image")

node_binary_image(<a href="#node_binary_image-name">name</a>, <a href="#node_binary_image-entry_point">entry_point</a>, <a href="#node_binary_image-data">data</a>, <a href="#node_binary_image-base">base</a>, <a href="#node_binary_image-user">user</a>, <a href="#node_binary_image-ports">ports</a>, <a href="#node_binary_image-volumes">volumes</a>, <a href="#node_binary_image-platform">platform</a>, <a href="#node_binary_image-visibility">visibility</a>,
                  <a href="#node_binary_image-testonly">testonly</a>)
</pre>

Builds a docker image that runs the entry_point script.

Example: [`@examples//api`](../../examples/api/BUILD.bazel#:~:text=name%20%3D%20%22api%22%2C)


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="node_binary_image-name"></a>name |  name of the target.   |  none |
| <a id="node_binary_image-entry_point"></a>entry_point |  JS file that is to be run. The cmd of the created image will be `node <entry_point>`   |  none |
| <a id="node_binary_image-data"></a>data |  ts_project(s) that are required for this app.   |  none |
| <a id="node_binary_image-base"></a>base |  docker base image, must contain the node binary.   |  `"@node_image_linux_amd64"` |
| <a id="node_binary_image-user"></a>user |  User the image runs with (must exist in the base image).   |  `"node"` |
| <a id="node_binary_image-ports"></a>ports |  Ports this image exposes (like EXPOSE in Dockerfile).   |  `[]` |
| <a id="node_binary_image-volumes"></a>volumes |  mount points this image uses (like VOLUME in Dockerfile). These should be full paths not names (e.g. `["/data"]`). For each of these, a directory owned by `user` is automatically created in the image (to allow the node process to actually write to it).<br><br>Note: Due to a missing feature in rules_oci ([rules_oci#406](https://github.com/bazel-contrib/rules_oci/issues/406)), setting this does currently not set the volume paths on the resulting image.<br><br>Since volumes are just metadata which we do not really use, this is OK-ish.   |  `[]` |
| <a id="node_binary_image-platform"></a>platform |  Platform to build the dependencies that go into the image for. Mostly relevant for Prisma engines. Defaults to Debian Linux with OpenSSL 3.x.   |  `Label("@dh_buildlib//private/docker:node_default_platform")` |
| <a id="node_binary_image-visibility"></a>visibility |  visibility of the main target.   |  `None` |
| <a id="node_binary_image-testonly"></a>testonly |  testonly flag.   |  `None` |


