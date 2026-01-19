"""Rule to extract a single file from an OCI image."""

def _extract_from_image_impl(ctx):
    args = ctx.actions.args()

    args.add("--input", ctx.file.image.path)
    args.add("--path", ctx.attr.path)
    args.add("--output", ctx.outputs.out)

    ctx.actions.run(
        inputs = [ctx.file.image],
        outputs = [ctx.outputs.out],
        arguments = [args],
        executable = ctx.executable._extractor,
        env = {"BAZEL_BINDIR": "."},
    )

extract_from_image = rule(
    doc = """Extracts a file from an OCI image.""",
    attrs = {
        "image": attr.label(
            allow_single_file = True,
            doc = "OCI image to extract from",
            mandatory = True,
        ),
        "out": attr.output(
            doc = "Output file",
            mandatory = True,
        ),
        "path": attr.string(
            doc = "Path inside the image to extract (no leading slash)",
            mandatory = True,
        ),
        "_extractor": attr.label(
            default = Label("//private/docker/src:extract-from-image"),
            executable = True,
            cfg = "exec",
        ),
    },
    implementation = _extract_from_image_impl,
)
