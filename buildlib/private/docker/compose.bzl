"""Rule to run docker-compose.yml files

They require Compose V2 (as part of the docker CLI).

Simply install via the docker repositories:

```
$ sudo apt-get install docker-compose-plugin
```
"""

load("@aspect_rules_js//js:libs.bzl", "js_binary_lib")
load("@bazel_skylib//lib:dicts.bzl", "dicts")
load("@dh_buildlib_private_ibazel_info//:is_ibazel.bzl", "is_ibazel")
load("@io_bazel_rules_docker//container:providers.bzl", "ImageInfo", "PullInfo")
load("@io_bazel_rules_docker//skylib:docker.bzl", "docker_path")
load("//private/ts:js_binary.bzl", "commonjs_transition")
load(":providers.bzl", "DockerComposeInfo", "HotReloadableInfo")
load(":pull_info.bzl", "pull_info_dict")

def _build_built_image_info(key, image, builder):
    digest_file = image[ImageInfo].container_parts["config_digest"]

    builder.digest_files.append(digest_file)
    builder.runfiles.append(image.default_runfiles)

    builder.image_infos[key] = {
        "digestFile": digest_file.path,
        "loadCmd": image.files_to_run.executable.short_path,
    }

def _build_hot_reload_info(ctx, key, info, builder):
    _build_built_image_info(key, info.image, builder)

    builder.runfiles.append(ctx.runfiles(transitive_files = info.files))

    builder.image_infos[key]["hotReload"] = {
        "containerPath": info.container_path,
        "files": [file.short_path for file in info.files.to_list()],
        "hostHomePath": ".cache/dh-buildlib/dc-hot/{}/{}/{}".format(ctx.attr.project, info.image.label.package, info.image.label.name),
    }

def _build_image_info(ctx, image, builder):
    key = str(image.label)

    if is_ibazel and HotReloadableInfo in image:
        _build_hot_reload_info(ctx, key, image[HotReloadableInfo], builder)
    elif ImageInfo in image:
        _build_built_image_info(key, image, builder)
    elif PullInfo in image:
        builder.image_infos[key] = pull_info_dict(image)
    else:
        fail("%s had neither ImageInfo nor PullInfo provider" % image.label)

def _write_image_info(ctx):
    builder = struct(
        digest_files = [],
        runfiles = [],
        image_infos = {},
    )

    for image in ctx.attr.deps:
        _build_image_info(ctx, image, builder)

    image_info_file = ctx.actions.declare_file(ctx.label.name + ".image-info.json")
    ctx.actions.write(image_info_file, json.encode(builder.image_infos))

    return struct(
        file = image_info_file,
        digest_files = builder.digest_files,
        runfiles = builder.runfiles,
    )

def _preprocess_dc(ctx, image_info_file, digest_files):
    inputs = [ctx.file.src, image_info_file] + digest_files

    new_dc = ctx.actions.declare_file("docker-compose.gen.yml")
    ctx.actions.run(
        inputs = inputs,
        outputs = [new_dc],
        arguments = [
            "--input",
            ctx.file.src.path,
            "--imageInfo",
            image_info_file.path,
            "--output",
            new_dc.path,
        ],
        env = {"BAZEL_BINDIR": "."},
        executable = ctx.executable._dc_processor,
    )

    return new_dc

def _docker_compose_up(ctx, dc_file, image_info_file, runfiles):
    docker_toolchain = ctx.toolchains["@io_bazel_rules_docker//toolchains/docker:toolchain_type"].info

    launcher = js_binary_lib.create_launcher(
        ctx,
        log_prefix_rule_set = "dh_buildlib",
        log_prefix_rule = "docker_compose",
        fixed_args = [
            docker_path(docker_toolchain),
            dc_file.short_path,
            ctx.attr.project,
            image_info_file.short_path,
        ],
    )

    runfiles = ctx.runfiles(files = [dc_file, image_info_file]).merge_all(
        [launcher.runfiles] + runfiles,
    )

    return DefaultInfo(
        executable = launcher.executable,
        runfiles = runfiles,
    )

def _docker_compose_impl(ctx):
    image_info = _write_image_info(ctx)

    new_dc = _preprocess_dc(ctx, image_info.file, image_info.digest_files)

    executable_info = _docker_compose_up(ctx, new_dc, image_info.file, image_info.runfiles)

    return [
        executable_info,
        DockerComposeInfo(
            project = ctx.attr.project,
            file = new_dc,
        ),
    ]

_docker_compose = rule(
    doc = """Docker Compose rule (js_binary-like rule)

    This is a bit of a frankenstein rule so that we can:
    - Take advantage of all the js_binary niceness.
    - Do the dc / manifest preprocessing.
    - Attach our own providers for dc_service_reference.
    All of that in the same rule (not macro), so that there are no magic names when using it.
    """,
    implementation = _docker_compose_impl,
    attrs = dicts.add(js_binary_lib.attrs, {
        "deps": attr.label_list(
            providers = [[ImageInfo], [PullInfo]],
            doc = "Container images required by this docker-compose file",
        ),
        "project": attr.string(),
        "src": attr.label(
            allow_single_file = [".yml"],
            doc = "The docker compose file",
        ),
        "_allowlist_function_transition": attr.label(
            default = "@bazel_tools//tools/allowlists/function_transition_allowlist",
        ),
        "_dc_processor": attr.label(
            default = Label("//private/docker/src:dc-processor"),
            executable = True,
            cfg = "exec",
        ),
    }),
    executable = True,
    toolchains = js_binary_lib.toolchains + ["@io_bazel_rules_docker//toolchains/docker:toolchain_type"],
    cfg = commonjs_transition,
)

def docker_compose(name, project, src, deps, visibility = None, testonly = None):
    """Bazel rule for docker compose files.

    Example: [`@examples//dc`](../../examples/dc/BUILD.bazel#:~:text=name%20%3D%20%22dc%22%2C)

    Args:
      name: Name of the rule.
      project: Name of the docker compose project.
        This is used as a prefix for the containers so it should be somewhat unique.
        If in doubt, a good default is the project tla (e.g. sbz for SBZ).
      src: The docker compose file (docker-compose.yml).
      deps: Container images required by this docker compose file.
      visibility: Visibility specifier.
      testonly: Testonly flag.
    """

    _docker_compose(
        name = name,
        project = project,
        src = src,
        deps = deps,
        entry_point = Label("//private/docker/src:dc-runner.js"),
        data = [Label("//private/docker/src")],
        visibility = visibility,
        testonly = testonly,
        enable_runfiles = True,
    )
