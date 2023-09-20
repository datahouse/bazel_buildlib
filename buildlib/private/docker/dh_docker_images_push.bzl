"""Rule to label and push docker images to docker.datarepo.ch."""

load("@io_bazel_rules_docker//container:container.bzl", "container_bundle", "container_image")
load("@io_bazel_rules_docker//contrib:push-all.bzl", "container_push")

def _load_stamp_data_impl(ctx):
    if ctx.attr.stamp:
        args = ctx.actions.args()

        args.add("--info-file", ctx.info_file)
        args.add_all(ctx.outputs.outs)

        ctx.actions.run(
            inputs = [ctx.info_file],
            outputs = ctx.outputs.outs,
            arguments = [args],
            env = {"BAZEL_BINDIR": "."},
            executable = ctx.executable._loader,
        )

    else:
        for out in ctx.outputs.outs:
            ctx.actions.write(out, "<unstamped bazel build>")

_load_stamp_data = rule(
    implementation = _load_stamp_data_impl,
    attrs = {
        "outs": attr.output_list(),
        "stamp": attr.bool(),
        "_loader": attr.label(
            default = Label("//private/docker/src:load-workspace-status"),
            executable = True,
            cfg = "exec",
        ),
    },
)

def dh_docker_images_push(name, images, repository_prefix):
    """Labels (stamps) and pushes image_names to docker.datarepo.ch

    Example: [`@examples//:docker-push`](../../examples/BUILD.bazel#:~:text=name%20%3D%20%22docker%2Dpush%22%2C)

    Args:
      name: Name of this rule. By convention, must be "docker-push". The
        name argument merely exists for consistency and to avoid breaking bazel tools.
      images: Dictionary from registry image name to build target.
      repository_prefix: Prefix of the images on docker.datarepo.ch.
        Typically "project-tla".
    """

    if name != "docker-push" or native.package_name() != "":
        fail("dh_docker_images_push must be at //:docker-push")

    _load_stamp_data(
        name = name + ".stamp-data",
        stamp = select({
            Label("//private:stamp"): True,
            "//conditions:default": False,
        }),
        outs = ["STABLE_GIT_COMMIT", "STABLE_GIT_REPO_URL", "STABLE_WEB_REPO_URL"],
    )

    for image_name, image_target in images.items():
        container_image(
            name = image_name + ".stamped",
            base = image_target,
            labels = {
                "org.opencontainers.image.revision": "@STABLE_GIT_COMMIT",
                "org.opencontainers.image.source": "@STABLE_GIT_REPO_URL",
                "org.opencontainers.image.url": "@STABLE_WEB_REPO_URL",
            },
        )

    full_prefix = "docker.datarepo.ch/" + repository_prefix

    # Real bundle.
    container_bundle(
        name = name + ".bundle",
        images = {
            # Set the tag with --embed_label
            full_prefix + "/" + image_name + ":{BUILD_EMBED_LABEL}": image_name + ".stamped"
            for image_name in images.keys()
        },
    )

    # Fake bundle to avoid pushing unstamped containers.
    container_bundle(
        name = name + ".empty.bundle",
    )

    container_push(
        name = name,
        format = "Docker",
        # Push the empty bundle in case we're not stamping:
        # This makes sure we never push unstamped containers.
        #
        # Even better would be to fail on run (but not on build).
        # However, for this we'd need support from container_push.
        bundle = select({
            Label("//private:stamp"): name + ".bundle",
            "//conditions:default": name + ".empty.bundle",
        }),
    )
