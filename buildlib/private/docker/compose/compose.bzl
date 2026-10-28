"""Rule to run docker-compose.yml files."""

load("@dh_buildlib_private_ibazel_info//:is_ibazel.bzl", "is_ibazel")
load("//private:launcher.bzl", "create_launcher")
load("//private/docker/lib:oci_util.bzl", "get_oci_dir")
load(":providers.bzl", "DockerComposeInfo", "HotReloadableInfo")

def _build_built_image_info(image_key, image_index, oci_dir, builder):
    builder.oci_images.append(oci_dir)

    return {
        "imageKey": image_key,
        "ociDir": oci_dir.path,
        "ociDirShort": oci_dir.short_path,
        # TODO: Use the image's canonical name once we have a way to specify it.
        "zotRepoName": "image%d" % image_index,
    }

def _build_hot_reload_info(image_key, image_index, image_label, hot_reload_info, builder):
    image_info = _build_built_image_info(image_key, image_index, hot_reload_info.oci_image, builder)

    builder.hot_reload_files.append(hot_reload_info.files)

    image_info["hotReload"] = {
        "containerPath": hot_reload_info.container_path,
        "files": [file.short_path for file in hot_reload_info.files.to_list()],
        "hostSubPath": "{}/{}".format(image_label.package, image_label.name),
    }

    return image_info

def _build_image_info(image_target, image_key, image_index, builder):
    if is_ibazel and HotReloadableInfo in image_target:
        return _build_hot_reload_info(image_key, image_index, image_target.label, image_target[HotReloadableInfo], builder)

    return _build_built_image_info(image_key, image_index, get_oci_dir(image_target), builder)

def _write_image_info(ctx):
    builder = struct(
        oci_images = [],
        hot_reload_files = [],
    )

    image_infos = [
        _build_image_info(image_target, image_key, image_index, builder)
        for image_index, (image_target, image_key) in enumerate(ctx.attr.deps.items())
    ]

    image_info_file = ctx.actions.declare_file(ctx.label.name + ".image-info.json")
    ctx.actions.write(image_info_file, json.encode(image_infos))

    return struct(
        file = image_info_file,
        oci_images = builder.oci_images,
        hot_reload_files = depset(transitive = builder.hot_reload_files),
    )

def _preprocess_dc(ctx, compose_file, image_info_file, oci_images):
    inputs = [compose_file, image_info_file] + oci_images

    new_dc = ctx.actions.declare_file("docker-compose.gen.yml")
    ctx.actions.run(
        inputs = inputs,
        outputs = [new_dc],
        arguments = [
            "--input",
            compose_file.path,
            "--imageInfo",
            image_info_file.path,
            "--output",
            new_dc.path,
        ],
        env = {"BAZEL_BINDIR": "."},
        executable = ctx.executable._dc_processor,
    )

    return new_dc

def _docker_compose_up(ctx, dc_file, image_info):
    dc_binary = ctx.executable._compose

    launcher = create_launcher(ctx, ctx.attr._dc_runner, fixed_args = [
        dc_binary.short_path,
        dc_file.short_path,
        ctx.attr.project,
        image_info.file.short_path,
    ])

    runfiles = launcher.runfiles.merge(ctx.runfiles(
        files = [dc_file, image_info.file, dc_binary] + image_info.oci_images + ctx.files.srcs,
        transitive_files = image_info.hot_reload_files,
    ))

    return DefaultInfo(
        executable = launcher.executable,
        runfiles = runfiles,
    )

def _select_compose_file(ctx):
    srcs = ctx.files.srcs

    compose_files = [
        f
        for f in srcs
        if f.extension in ["yml", "yaml"] and f.basename.startswith("docker-compose.")
    ]
    if len(compose_files) != 1:
        fail("srcs must include exactly one file starting with 'docker-compose.' and ending with '.yml|.yaml'.")

    return compose_files[0]

def _docker_compose_impl(ctx):
    image_info = _write_image_info(ctx)

    compose_file = _select_compose_file(ctx)

    new_dc = _preprocess_dc(ctx, compose_file, image_info.file, image_info.oci_images)

    executable_info = _docker_compose_up(ctx, new_dc, image_info)

    return [
        executable_info,
        DockerComposeInfo(
            project = ctx.attr.project,
            file = new_dc,
        ),
    ]

_docker_compose = rule(
    doc = """Docker Compose rule.""",
    implementation = _docker_compose_impl,
    attrs = {
        "deps": attr.label_keyed_string_dict(
            doc = """Container images required by this docker-compose file.

            This is a dict to preserve to original label strings (for use inside the docker-compose.yml).
            """,
            allow_files = True,
        ),
        "project": attr.string(),
        "srcs": attr.label_list(
            allow_files = True,
            doc = "Docker compose inputs: must include exactly one file starting with 'docker-compose.' and ends with '.yml|.yaml'; other files (e.g. .env) are included as runfiles.",
        ),
        "_compose": attr.label(
            default = Label("@compose"),
            executable = True,
            cfg = "exec",
        ),
        "_dc_processor": attr.label(
            default = Label("//private/docker/compose/src:dc-processor"),
            executable = True,
            cfg = "exec",
        ),
        "_dc_runner": attr.label(
            default = Label("//private/docker/compose/src:dc-runner"),
            executable = True,
            cfg = "exec",
        ),
    },
    executable = True,
)

def docker_compose(name, project, srcs, deps = None, visibility = None, testonly = None):
    """Bazel rule for docker compose files.

    Example: [`@examples//dc`](../../examples/dc/BUILD.bazel#:~:text=name%20%3D%20%22dc%22%2C)

    Args:
      name: Name of the rule.
      project: Name of the docker compose project.
        This is used as a prefix for the containers so it should be somewhat unique.
        If in doubt, a good default is the project tla (e.g. sbz for SBZ).
      srcs: Docker compose inputs: must include exactly one file starting with 'docker-compose.' and ends with '.yml|.yaml'; other files (e.g. .env) are included as runfiles.
      deps: Container images required by this docker compose file.
      visibility: Visibility specifier.
      testonly: Testonly flag.
    """

    _docker_compose(
        name = name,
        project = project,
        srcs = srcs,
        deps = {d: d for d in deps},  # key will be implicitly converted to label.
        visibility = visibility,
        testonly = testonly,
    )
