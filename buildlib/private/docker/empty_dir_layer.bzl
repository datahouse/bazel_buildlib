"""Macro to create a docker image layer containing empty directories."""

load("@io_bazel_rules_docker//container:container.bzl", "container_layer")
load("@io_bazel_rules_docker//container:providers.bzl", "ImageInfo", "ImportInfo")

def _container_parts(target):
    if ImportInfo in target:
        return target[ImportInfo].container_parts

    return target[ImageInfo].container_parts

def _empty_dir_layer_tar_impl(ctx):
    args = ctx.actions.args()

    layers = _container_parts(ctx.attr.base)["zipped_layer"]

    args.add_all("--layer", layers)
    args.add_all("--path", ctx.attr.paths)
    args.add("--user", ctx.attr.user)
    args.add("--output", ctx.outputs.out)

    ctx.actions.run(
        inputs = layers,
        outputs = [ctx.outputs.out],
        arguments = [args],
        executable = ctx.executable._builder,
        env = {"BAZEL_BINDIR": "."},
    )

_empty_dir_layer_tar = rule(
    attrs = {
        "base": attr.label(
            providers = [[ImageInfo], [ImportInfo]],
        ),
        "out": attr.output(),
        "paths": attr.string_list(),
        "user": attr.string(),
        "_builder": attr.label(
            default = Label("//private/docker/src:empty-dir-layer"),
            executable = True,
            cfg = "exec",
        ),
    },
    implementation = _empty_dir_layer_tar_impl,
)

def empty_dir_layer(name, base, user, paths):
    _empty_dir_layer_tar(
        name = name + "_gen_tar",
        base = base,
        user = user,
        paths = paths,
        out = name + ".gen.tar.gz",
    )

    container_layer(
        name = name,
        tars = [name + ".gen.tar.gz"],
    )
