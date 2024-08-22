"""Rule to build a Dockerfile in a docker daemon."""

def _build_dockerfile_impl(ctx):
    out_dir = ctx.actions.declare_directory(ctx.label.name)

    args = ctx.actions.args()
    args.add("--outputDir", out_dir.path)
    args.add("--dockerfile", ctx.file.src)
    args.add("--baseImage", ctx.file.base.path)

    ctx.actions.run(
        inputs = [ctx.file.src, ctx.file.base],
        outputs = [out_dir],
        arguments = [args],
        executable = ctx.executable._builder,
        env = {"BAZEL_BINDIR": "."},
        mnemonic = "DockerBuild",
        progress_message = "Building %s" % ctx.file.src.short_path,
        # Access to docker socket.
        execution_requirements = {"requires-network": ""},
    )

    return DefaultInfo(files = depset([out_dir]))

build_dockerfile = rule(
    doc = """Build a Dockerfile using a local docker daemon.

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
    """,
    implementation = _build_dockerfile_impl,
    attrs = {
        "base": attr.label(
            doc = """The base image to use.

            A reference for this image will be passed as `BASE_IMAGE` build argument to docker.
            """,
            allow_single_file = True,
            mandatory = True,
        ),
        "src": attr.label(
            doc = "The Dockerfile to build.",
            mandatory = True,
            allow_single_file = True,
        ),
        "_builder": attr.label(
            default = Label("//private/docker/src:build-dockerfile"),
            executable = True,
            cfg = "exec",
        ),
    },
)
