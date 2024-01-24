<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Docker and docker compose related rules.

<a id="dc_service_reference"></a>

## dc_service_reference

<pre>
dc_service_reference(<a href="#dc_service_reference-name">name</a>, <a href="#dc_service_reference-dc">dc</a>, <a href="#dc_service_reference-index">index</a>, <a href="#dc_service_reference-port">port</a>, <a href="#dc_service_reference-service_name">service_name</a>)
</pre>

Reference to an exposed port of a docker service.

Example: [`@examples//dc:db`](../../examples/dc/BUILD.bazel#:~:text=name%20%3D%20%22db%22%2C)

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="dc_service_reference-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="dc_service_reference-dc"></a>dc |  Docker compose rule that contains the target service   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="dc_service_reference-index"></a>index |  Index of the replica   | Integer | optional |  `1`  |
| <a id="dc_service_reference-port"></a>port |  Internal port of the service   | Integer | required |  |
| <a id="dc_service_reference-service_name"></a>service_name |  Docker compose service name   | String | required |  |


<a id="container_pull"></a>

## container_pull

<pre>
container_pull(<a href="#container_pull-name">name</a>, <a href="#container_pull-registry">registry</a>, <a href="#container_pull-repository">repository</a>, <a href="#container_pull-digest">digest</a>, <a href="#container_pull-tag">tag</a>, <a href="#container_pull-os">os</a>, <a href="#container_pull-architecture">architecture</a>)
</pre>

Pulls a docker image from a docker registry.

This is a repository rule, you can only use it in the WORKSPACE file.

Example: [`example/WORKSPACE`](../../examples/WORKSPACE#:~:text=name%20%3D%20%22nginx_image%22%2C).

This calls
[oci_pull](https://github.com/bazel-contrib/rules_oci/blob/main/docs/pull.md)
under the hood.


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="container_pull-name"></a>name |  name of the repository   |  none |
| <a id="container_pull-registry"></a>registry |  registry to pull from (e.g. `index.docker.io`)   |  none |
| <a id="container_pull-repository"></a>repository |  repository to pull (e.g. `nginx`)   |  none |
| <a id="container_pull-digest"></a>digest |  digest to pull (e.g. `sha256:abcdef...`)   |  none |
| <a id="container_pull-tag"></a>tag |  tag to pull (e.g. `2.3.4`). This is for documentation purposes / renovate only. The actual image is determined via the digest.   |  none |
| <a id="container_pull-os"></a>os |  Operating system to pull for (typically `linux`). This is for documentation purposes / renovate only. The actual image is determined via the digest.   |  none |
| <a id="container_pull-architecture"></a>architecture |  Architecture to pull for (typically `amd64`). This is for documentation purposes / renovate only. The actual image is determined via the digest.   |  none |


<a id="dh_docker_images_push"></a>

## dh_docker_images_push

<pre>
dh_docker_images_push(<a href="#dh_docker_images_push-name">name</a>, <a href="#dh_docker_images_push-images">images</a>, <a href="#dh_docker_images_push-repository_prefix">repository_prefix</a>)
</pre>

Labels (stamps) and pushes image_names to docker.datarepo.ch

Example: [`@examples//:docker-push`](../../examples/BUILD.bazel#:~:text=name%20%3D%20%22docker%2Dpush%22%2C)


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="dh_docker_images_push-name"></a>name |  Name of this rule. By convention, must be "docker-push". The name argument merely exists for consistency and to avoid breaking bazel tools.   |  none |
| <a id="dh_docker_images_push-images"></a>images |  Dictionary from registry image name to build target.   |  none |
| <a id="dh_docker_images_push-repository_prefix"></a>repository_prefix |  Prefix of the images on docker.datarepo.ch. Typically "project-tla".   |  none |


<a id="docker_compose"></a>

## docker_compose

<pre>
docker_compose(<a href="#docker_compose-name">name</a>, <a href="#docker_compose-project">project</a>, <a href="#docker_compose-src">src</a>, <a href="#docker_compose-deps">deps</a>, <a href="#docker_compose-visibility">visibility</a>, <a href="#docker_compose-testonly">testonly</a>)
</pre>

Bazel rule for docker compose files.

Example: [`@examples//dc`](../../examples/dc/BUILD.bazel#:~:text=name%20%3D%20%22dc%22%2C)


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="docker_compose-name"></a>name |  Name of the rule.   |  none |
| <a id="docker_compose-project"></a>project |  Name of the docker compose project. This is used as a prefix for the containers so it should be somewhat unique. If in doubt, a good default is the project tla (e.g. sbz for SBZ).   |  none |
| <a id="docker_compose-src"></a>src |  The docker compose file (docker-compose.yml).   |  none |
| <a id="docker_compose-deps"></a>deps |  Container images required by this docker compose file.   |  none |
| <a id="docker_compose-visibility"></a>visibility |  Visibility specifier.   |  `None` |
| <a id="docker_compose-testonly"></a>testonly |  Testonly flag.   |  `None` |


<a id="docker_image_for_ts_test"></a>

## docker_image_for_ts_test

<pre>
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
| <a id="node_binary_image-base"></a>base |  docker base image, must contain the node binary.   |  `"@node_image"` |
| <a id="node_binary_image-user"></a>user |  User the image runs with (must exist in the base image).   |  `"node"` |
| <a id="node_binary_image-ports"></a>ports |  Ports this image exposes (like EXPOSE in Dockerfile).   |  `[]` |
| <a id="node_binary_image-volumes"></a>volumes |  mount points this image uses (like VOLUME in Dockerfile). These should be full paths not names (e.g. `["/data"]`). For each of these, a directory owned by `user` is automatically created in the image (to allow the node process to actually write to it).<br><br>Note: Due to a missing feature in rules_oci ([rules_oci#406](https://github.com/bazel-contrib/rules_oci/issues/406)), setting this does currently not set the volume paths on the resulting image.<br><br>Since volumes are just metadata which we do not really use, this is OK-ish.   |  `[]` |
| <a id="node_binary_image-platform"></a>platform |  Platform to build the dependencies that go into the image for. Mostly relevant for Prisma engines. Defaults to Debian Linux with OpenSSL 3.x.   |  `Label("//private/docker:node_default_platform")` |
| <a id="node_binary_image-visibility"></a>visibility |  visibility of the main target.   |  `None` |
| <a id="node_binary_image-testonly"></a>testonly |  testonly flag.   |  `None` |


