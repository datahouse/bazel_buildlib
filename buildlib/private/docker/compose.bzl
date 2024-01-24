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
load("//private/ts:js_binary.bzl", "commonjs_transition")
load(":oci_util.bzl", "get_oci_dir")
load(":providers.bzl", "DockerComposeInfo", "HotReloadableInfo")

def _build_built_image_info(keys, oci_dir, builder):
    builder.oci_images.append(oci_dir)

    return {
        "keys": keys,
        "ociDir": oci_dir.path,
        "ociDirShort": oci_dir.short_path,
    }

def _build_hot_reload_info(ctx, keys, image_label, hot_reload_info, builder):
    image_info = _build_built_image_info(keys, hot_reload_info.oci_image, builder)

    builder.hot_reload_files.append(hot_reload_info.files)

    image_info["hotReload"] = {
        "containerPath": hot_reload_info.container_path,
        "files": [file.short_path for file in hot_reload_info.files.to_list()],
        "hostHomePath": ".cache/dh-buildlib/dc-hot/{}/{}/{}".format(ctx.attr.project, image_label.package, image_label.name),
    }

    return image_info

def _build_image_info(ctx, image_target, image_key, builder):
    keys = [
        image_key,
        str(image_target.label),  # backwards compatibility
    ]

    if is_ibazel and HotReloadableInfo in image_target:
        return _build_hot_reload_info(ctx, keys, image_target.label, image_target[HotReloadableInfo], builder)

    return _build_built_image_info(keys, get_oci_dir(image_target), builder)

def _write_image_info(ctx):
    builder = struct(
        oci_images = [],
        hot_reload_files = [],
    )

    image_infos = [
        _build_image_info(ctx, image_target, image_key, builder)
        for image_target, image_key in ctx.attr.deps.items()
    ]

    image_info_file = ctx.actions.declare_file(ctx.label.name + ".image-info.json")
    ctx.actions.write(image_info_file, json.encode(image_infos))

    return struct(
        file = image_info_file,
        oci_images = builder.oci_images,
        hot_reload_files = depset(transitive = builder.hot_reload_files),
    )

def _preprocess_dc(ctx, image_info_file, oci_images):
    inputs = [ctx.file.src, image_info_file] + oci_images

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

def _docker_compose_up(ctx, dc_file, image_info):
    launcher = js_binary_lib.create_launcher(
        ctx,
        log_prefix_rule_set = "dh_buildlib",
        log_prefix_rule = "docker_compose",
        fixed_args = [
            dc_file.short_path,
            ctx.attr.project,
            image_info.file.short_path,
        ],
    )

    runfiles = ctx.runfiles(
        files = [dc_file, image_info.file] + image_info.oci_images,
        transitive_files = image_info.hot_reload_files,
    ).merge(launcher.runfiles)

    return DefaultInfo(
        executable = launcher.executable,
        runfiles = runfiles,
    )

def _docker_compose_impl(ctx):
    image_info = _write_image_info(ctx)

    new_dc = _preprocess_dc(ctx, image_info.file, image_info.oci_images)

    executable_info = _docker_compose_up(ctx, new_dc, image_info)

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
        "deps": attr.label_keyed_string_dict(
            doc = """Container images required by this docker-compose file.

            This is a dict to preserve to original label strings (for use inside the docker-compose.yml).
            """,
            allow_files = True,
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
    toolchains = js_binary_lib.toolchains,
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
        deps = {d: d for d in deps},  # key will be implicitly converted to label.
        entry_point = Label("//private/docker/src:dc-runner.js"),
        data = [Label("//private/docker/src")],
        visibility = visibility,
        testonly = testonly,
        enable_runfiles = True,
    )
