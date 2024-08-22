<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Docker repository rules.

You can only use these rules in the WORKSPACE file.


## Functions

- [container_pull](#container_pull)


<a id="container_pull"></a>

## container_pull

<pre>
load("@dh_buildlib//docker:repositories.bzl", "container_pull")

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
| <a id="container_pull-digest"></a>digest |  digest to pull (e.g. `sha256:abcdef...`), which can be found by running: `docker manifest inspect [IMAGE]:[TAG]`   |  none |
| <a id="container_pull-tag"></a>tag |  tag to pull (e.g. `2.3.4`). This is for documentation purposes / renovate only. The actual image is determined via the digest.   |  none |
| <a id="container_pull-os"></a>os |  Operating system to pull for (typically `linux`).   |  none |
| <a id="container_pull-architecture"></a>architecture |  Architecture to pull for (typically `amd64`).   |  none |


