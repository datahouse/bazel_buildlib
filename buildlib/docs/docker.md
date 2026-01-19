<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Docker and docker compose related rules.


## Rules

- [build_dockerfile](#build_dockerfile)
- [dc_service_reference](#dc_service_reference)
- [extract_from_image](#extract_from_image)

## Macros

- [dh_docker_images_push](#dh_docker_images_push)

## Functions

- [docker_compose](#docker_compose)


<a id="build_dockerfile"></a>

## build_dockerfile

<pre>
load("@dh_buildlib//docker:defs.bzl", "build_dockerfile")

build_dockerfile(<a href="#build_dockerfile-name">name</a>, <a href="#build_dockerfile-src">src</a>, <a href="#build_dockerfile-base">base</a>)
</pre>

Build a Dockerfile using a local docker daemon.

This rule only exists as an escape-hatch if running a command under docker is
required to build an image (e.g. [optimizing a keycloak image][kc_optimize]).

If possible, you should use [`node_binary_image`](#node_binary_image) or
[`oci_image`][oci_image] instead of this rule.

Attention: The docker build does not have internet access! This is intended
to avoid non-hermetic builds. If you need files form the internet, download
them with bazel and inject them via the base image.

Example:

```Dockerfile
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

RUN my-build-command
```

[oci_image]: https://github.com/bazel-contrib/rules_oci/blob/main/docs/image.md#oci_image
[kc_optimize]: https://www.keycloak.org/server/containers#_writing_your_optimized_keycloak_dockerfile

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="build_dockerfile-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="build_dockerfile-src"></a>src |  The Dockerfile to build.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="build_dockerfile-base"></a>base |  The base image to use.<br><br>A reference for this image will be passed as `BASE_IMAGE` build argument to docker.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |


<a id="dc_service_reference"></a>

## dc_service_reference

<pre>
load("@dh_buildlib//docker:defs.bzl", "dc_service_reference")

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


<a id="extract_from_image"></a>

## extract_from_image

<pre>
load("@dh_buildlib//docker:defs.bzl", "extract_from_image")

extract_from_image(<a href="#extract_from_image-name">name</a>, <a href="#extract_from_image-out">out</a>, <a href="#extract_from_image-image">image</a>, <a href="#extract_from_image-path">path</a>)
</pre>

Extracts a file from an OCI image.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="extract_from_image-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="extract_from_image-out"></a>out |  Output file   | <a href="https://bazel.build/concepts/labels">Label</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | required |  |
| <a id="extract_from_image-image"></a>image |  OCI image to extract from   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="extract_from_image-path"></a>path |  Path inside the image to extract (no leading slash)   | String | required |  |


<a id="docker_compose"></a>

## docker_compose

<pre>
load("@dh_buildlib//docker:defs.bzl", "docker_compose")

docker_compose(<a href="#docker_compose-name">name</a>, <a href="#docker_compose-project">project</a>, <a href="#docker_compose-src">src</a>, <a href="#docker_compose-deps">deps</a>, <a href="#docker_compose-srcs">srcs</a>, <a href="#docker_compose-visibility">visibility</a>, <a href="#docker_compose-testonly">testonly</a>)
</pre>

Bazel rule for docker compose files.

Example: [`@examples//dc`](../../examples/dc/BUILD.bazel#:~:text=name%20%3D%20%22dc%22%2C)


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="docker_compose-name"></a>name |  Name of the rule.   |  none |
| <a id="docker_compose-project"></a>project |  Name of the docker compose project. This is used as a prefix for the containers so it should be somewhat unique. If in doubt, a good default is the project tla (e.g. sbz for SBZ).   |  none |
| <a id="docker_compose-src"></a>src |  Deprecated use srcs. The docker compose file (docker-compose.yml). Mutually exclusive with srcs.   |  `None` |
| <a id="docker_compose-deps"></a>deps |  Container images required by this docker compose file.   |  `None` |
| <a id="docker_compose-srcs"></a>srcs |  Docker compose inputs: must include exactly one file starting with 'docker-compose.' and ends with '.yml\|.yaml'; other files (e.g. .env) are included as runfiles. Mutually exclusive with src.   |  `None` |
| <a id="docker_compose-visibility"></a>visibility |  Visibility specifier.   |  `None` |
| <a id="docker_compose-testonly"></a>testonly |  Testonly flag.   |  `None` |


<a id="dh_docker_images_push"></a>

## dh_docker_images_push

<pre>
load("@dh_buildlib//docker:defs.bzl", "dh_docker_images_push")

dh_docker_images_push(*, <a href="#dh_docker_images_push-name">name</a>, <a href="#dh_docker_images_push-images">images</a>, <a href="#dh_docker_images_push-visibility">visibility</a>)
</pre>

Labels (stamps) and pushes image_names to docker.datarepo.ch

Note: This macro should only be used in the top-level package and called "docker-push".
Otherwise, it-drone-bazel will not push the images correctly.

Example: [`@examples//:docker-push`](../../examples/BUILD.bazel#:~:text=name%20%3D%20%22docker%2Dpush%22%2C)

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="dh_docker_images_push-name"></a>name |  A unique name for this macro instance. Normally, this is also the name for the macro's main or only target. The names of any other targets that this macro might create will be this name with a string suffix.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="dh_docker_images_push-images"></a>images |  Dictionary from registry image name to build target.   | Dictionary: String -> Label; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | required |  |
| <a id="dh_docker_images_push-visibility"></a>visibility |  The visibility to be passed to this macro's exported targets. It always implicitly includes the location where this macro is instantiated, so this attribute only needs to be explicitly set if you want the macro's targets to be additionally visible somewhere else.   | <a href="https://bazel.build/concepts/labels">List of labels</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  |


