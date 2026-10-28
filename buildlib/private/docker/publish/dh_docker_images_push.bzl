"""Rule to annotate and push docker images to docker.datarepo.ch."""

load("@bazel_lib//lib:stamping.bzl", "STAMP_ATTRS", "maybe_stamp")
load("@bazel_skylib//lib:dicts.bzl", "dicts")
load("@rules_oci//oci:defs.bzl", "oci_image")
load("//private:launcher.bzl", "create_launcher")
load("//private/docker/lib:oci_util.bzl", "get_oci_dir")
load(":image_annotations.bzl", "image_annotations")

def _oci_pushes_impl(ctx):
    crane = ctx.toolchains["@rules_oci//oci:crane_toolchain_type"]

    image_info = {
        name: get_oci_dir(target).short_path
        for name, target in ctx.attr.images.items()
    }

    image_info_file = ctx.actions.declare_file("%s-image-infos.json" % ctx.label.name)
    ctx.actions.write(image_info_file, json.encode(image_info))

    launcher = create_launcher(ctx, ctx.attr._oci_pusher, fixed_args = [
        crane.crane_info.binary.short_path,
        "true" if maybe_stamp(ctx) else "false",
        ctx.attr.prefix,
        ctx.file._remote_tag.short_path,
        image_info_file.short_path,
    ])

    runfiles = launcher.runfiles.merge_all([
        ctx.runfiles(files = [ctx.file._remote_tag, image_info_file] + ctx.files.images),
        crane.default.default_runfiles,
    ])
    return DefaultInfo(
        executable = launcher.executable,
        runfiles = runfiles,
    )

_oci_pushes = rule(
    doc = """
    Rule to push multiple docker images to a registry.

    This is our own rule (instead of some multi-run of oci_push), because
    oci_push isn't handling transitions sufficiently well: We'd need to get
    the oci_push target in the exec configuration. However, oci_push would need
    to get its dependencies in the target configuration.

    It seems it doesn't do that. Therefore, we write our own pusher. This also
    allows us to put in a couple of defenses against pushing improperly stamped images.

    The pusher is an adjusted js_binary rule so we can use the `fixed_args` machinery.
    """,
    implementation = _oci_pushes_impl,
    attrs = dicts.add(
        STAMP_ATTRS,
        {
            "images": attr.string_keyed_label_dict(),
            "prefix": attr.string(),
            "_oci_pusher": attr.label(
                default = "//private/docker/publish/src:oci-pusher",
                cfg = "exec",
                executable = True,
            ),
            "_remote_tag": attr.label(
                allow_single_file = True,
                default = ":push-tag.txt",
            ),
        },
    ),
    executable = True,
    toolchains = ["@rules_oci//oci:crane_toolchain_type"],
)

def _dh_docker_images_push_impl(name, images, prefix, visibility):
    for image_name, image_target in images.items():
        name_prefix = name + "_" + image_name

        image_annotations(
            name = name_prefix + ".annotations",
            annotations = name_prefix + ".annotations.txt",
            image = image_target,
        )

        oci_image(
            name = name_prefix + ".stamped",
            base = image_target,
            created = Label(":build-time.txt"),
            annotations = name_prefix + ".annotations",
        )

    _oci_pushes(
        name = "docker-push",
        images = {
            image_name: name + "_" + image_name + ".stamped"
            for image_name in images
        },
        prefix = prefix,
        visibility = visibility,
    )

dh_docker_images_push = macro(
    doc = """Annotates (stamps) and pushes `images` to docker.datarepo.ch

    Note: This macro should only be used in the top-level package and called "docker-push".
    Otherwise, [it-drone-bazel](https://git.datahouse.ch/datahouse/it-drone-bazel) will not push the images correctly.

    Running `:docker-push` pushes every entry of `images` to `docker.datarepo.ch/<prefix>/<image>` where:

    * `<image>` is the key of the dictionary entry.
    * `<prefix>` is (by default) inferred from the git repository name (lower-case of repo name)[^subdir].

    Example: [`@examples//:docker-push`](../../examples/BUILD.bazel#:~:text=name%20%3D%20%22docker%2Dpush%22%2C)

    You can test what this rule would do locally by using the `--dry-run` flag:

    ```sh
    examples$ DRONE_REPO_NAME=fake-repo-name \\
      DRONE_WORKSPACE=$(pwd) \\
      bazel run \\
      --workspace_status_command scripts/git_workspace_status.sh \\
      --stamp --embed_label=test \\
      :docker-push -- --dry-run
    ```

    [^subdir]: If the bazel workspace is not in the root of the git repository, the relative bazel workspace sub-directory is appended, but this is a niche use-case.
    """,
    attrs = {
        "images": attr.string_keyed_label_dict(
            doc = "Dictionary from registry image name to build target.",
            mandatory = True,
            allow_empty = False,
            configurable = False,
        ),
        "prefix": attr.string(
            doc = "Overrides the automatically inferred prefix (if set). Empty string means infer.",
            # It would of course be much nicer to use presence of this attribute to determine infer state,
            # but it seems bazel does not support this (a default value is enforced).
            mandatory = False,
            configurable = False,
            default = "",
        ),
    },
    implementation = _dh_docker_images_push_impl,
)
