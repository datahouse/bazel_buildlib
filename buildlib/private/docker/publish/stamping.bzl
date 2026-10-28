"""Internal rule to load stamping data for docker images (before pushing)."""

load("@bazel_lib//lib:stamping.bzl", "STAMP_ATTRS", "maybe_stamp")

def _load_stamp_data_impl(ctx):
    stamp = maybe_stamp(ctx)

    if stamp:
        args = ctx.actions.args()

        args.add("--stableStatusFile", stamp.stable_status_file)
        args.add("--volatileStatusFile", stamp.volatile_status_file)
        args.add("--buildTimeFile", ctx.outputs.build_time)
        args.add("--tagFile", ctx.outputs.docker_tag)

        ctx.actions.run(
            inputs = [
                stamp.stable_status_file,
                stamp.volatile_status_file,
            ],
            outputs = [ctx.outputs.build_time, ctx.outputs.docker_tag],
            arguments = [args],
            env = {"BAZEL_BINDIR": "."},
            executable = ctx.executable._loader,
        )

    else:
        ctx.actions.write(ctx.outputs.docker_tag, "")
        ctx.actions.write(ctx.outputs.build_time, "1970-01-01T00:00:00Z")  # epoch

load_stamp_data = rule(
    doc = """Stamp data common to all OCI images.""",
    implementation = _load_stamp_data_impl,
    attrs = dict({
        "build_time": attr.output(
            doc = """Output file containing the build time in ISO8601 format.""",
            mandatory = True,
        ),
        "docker_tag": attr.output(
            doc = """Output file containing the tag to apply to the docker image.""",
            mandatory = True,
        ),
        "_loader": attr.label(
            default = Label("//private/docker/publish/src:load-stamp-data"),
            executable = True,
            cfg = "exec",
        ),
    }, **STAMP_ATTRS),
)
