"""Rule to label and push docker images to docker.datarepo.ch.

Note to implementers: You can test what this rule would do locally using the --dry-run flag:

examples$ bazel run \
  --workspace_status_command scripts/git_workspace_status.sh \
  --stamp --embed_label=test \
  :docker-push -- --dry-run
"""

load("@aspect_bazel_lib//lib:stamping.bzl", "STAMP_ATTRS", "maybe_stamp")
load("@aspect_rules_js//js:libs.bzl", "js_binary_lib")
load("@bazel_skylib//lib:dicts.bzl", "dicts")
load("@rules_oci//oci:defs.bzl", "oci_image")
load(":oci_util.bzl", "get_oci_dir")

def _oci_pushes_impl(ctx):
    crane = ctx.toolchains["@rules_oci//oci:crane_toolchain_type"]

    image_info = {
        name: get_oci_dir(target).short_path
        for name, target in ctx.attr.images.items()
    }

    image_info_file = ctx.actions.declare_file("%s-image-infos.json" % ctx.label.name)
    ctx.actions.write(image_info_file, json.encode(image_info))

    args = [
        "--cranePath",
        crane.crane_info.binary.short_path,
        "--stamp",
        "true" if maybe_stamp(ctx) else "false",
        "--tagFile",
        ctx.file.remote_tag.short_path,
        "--imageInfoFile",
        image_info_file.short_path,
    ]

    launcher = js_binary_lib.create_launcher(
        ctx,
        log_prefix_rule_set = "dh_buildlib",
        log_prefix_rule = "oci_images_push",
        fixed_args = args,
    )

    runfiles = ctx.runfiles(
        files = [ctx.file.remote_tag, image_info_file] + ctx.files.images,
    ).merge_all([launcher.runfiles, crane.default.default_runfiles])

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
        js_binary_lib.attrs,
        STAMP_ATTRS,
        {
            "images": attr.string_keyed_label_dict(),
            "remote_tag": attr.label(allow_single_file = True),
        },
    ),
    executable = True,
    toolchains = js_binary_lib.toolchains + [
        "@rules_oci//oci:crane_toolchain_type",
    ],
)

def _dh_docker_images_push_impl(name, images, visibility):
    for image_name, image_target in images.items():
        oci_image(
            name = name + "_" + image_name + ".stamped",
            base = image_target,
            labels = Label(":push-labels.txt"),
        )

    _oci_pushes(
        name = "docker-push",
        remote_tag = Label(":push-tag.txt"),
        images = {
            image_name: name + "_" + image_name + ".stamped"
            for image_name in images
        },
        entry_point = Label("//private/docker/src:oci-pusher.js"),
        data = [Label("//private/docker/src")],
        enable_runfiles = True,
        visibility = visibility,
    )

dh_docker_images_push = macro(
    doc = """Labels (stamps) and pushes image_names to docker.datarepo.ch

    Note: This macro should only be used in the top-level package and called "docker-push".
    Otherwise, it-drone-bazel will not push the images correctly.

    Example: [`@examples//:docker-push`](../../examples/BUILD.bazel#:~:text=name%20%3D%20%22docker%2Dpush%22%2C)
    """,
    attrs = {
        "images": attr.string_keyed_label_dict(
            doc = "Dictionary from registry image name to build target.",
            mandatory = True,
            allow_empty = False,
            configurable = False,
        ),
    },
    implementation = _dh_docker_images_push_impl,
)
