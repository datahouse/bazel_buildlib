"""Rule to extract a single file from an OCI image."""

def _extract_from_image_impl(ctx):
    args = ctx.actions.args()

    # Unfortunately, bazel enforces a default value on attrs.
    # So we have to interpret empty strings as missing.
    if bool(ctx.attr.path) == bool(ctx.attr.path_regexp):
        fail("you must set exactly one of path / path_regexp")

    args.add("--input", ctx.file.image.path)
    args.add("--output", ctx.outputs.out)

    if ctx.attr.path:
        args.add("--path", ctx.attr.path)

    if ctx.attr.path_regexp:
        args.add("--regexp", ctx.attr.path_regexp)

    ctx.actions.run(
        inputs = [ctx.file.image],
        outputs = [ctx.outputs.out],
        arguments = [args],
        executable = ctx.executable._extractor,
        env = {"BAZEL_BINDIR": "."},
    )

extract_from_image = rule(
    doc = """Extracts a file from an OCI image.

    Supports literal paths or path regular expressions.

    * Paths do not have a leading slash.
    * Regular expressions are passed to JS new RegExp
    * Regular expression tests are **not** anchored (you have to anchor).

    Performs best-effort conflict / duplicate detection.
    """,
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
            doc = "Path inside the image to extract",
        ),
        "path_regexp": attr.string(
            doc = "Regexp to match path against",
        ),
        "_extractor": attr.label(
            default = Label("//private/docker/build/src:extract-from-image"),
            executable = True,
            cfg = "exec",
        ),
    },
    implementation = _extract_from_image_impl,
)
