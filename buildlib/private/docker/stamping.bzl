"""Internal rule to load stamping data for docker images (before pushing)."""

load("@aspect_bazel_lib//lib:stamping.bzl", "STAMP_ATTRS", "maybe_stamp")

def _load_stamp_data_impl(ctx):
    stamp = maybe_stamp(ctx)

    if stamp:
        args = ctx.actions.args()

        args.add("--infoFile", stamp.stable_status_file)
        args.add("--labelsFile", ctx.outputs.labels)
        args.add("--tagFile", ctx.outputs.docker_tag)

        ctx.actions.run(
            inputs = [stamp.stable_status_file],
            outputs = [ctx.outputs.labels, ctx.outputs.docker_tag],
            arguments = [args],
            env = {"BAZEL_BINDIR": "."},
            executable = ctx.executable._loader,
        )

    else:
        ctx.actions.write(ctx.outputs.labels, "")
        ctx.actions.write(ctx.outputs.docker_tag, "")

load_stamp_data = rule(
    doc = """Internal rule to transform bazel workspace status into a rules_oci friendly format.""",
    implementation = _load_stamp_data_impl,
    attrs = dict({
        "docker_tag": attr.output(
            doc = """Output file containing the tag to apply to the docker image.""",
            mandatory = True,
        ),
        "labels": attr.output(
            doc = """Output file containing the labels to apply to the docker image.""",
            mandatory = True,
        ),
        "_loader": attr.label(
            default = Label("//private/docker/src:load-stamp-data"),
            executable = True,
            cfg = "exec",
        ),
    }, **STAMP_ATTRS),
)
