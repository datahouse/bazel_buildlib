"""Internal rule to build image annotations for OCI images."""

load("@bazel_lib//lib:stamping.bzl", "STAMP_ATTRS", "maybe_stamp")
load("@package_metadata//providers:package_metadata_info.bzl", "PackageMetadataInfo")

_BaseImageMetadataInfo = provider(
    doc = """Internal provider for OCI base image provenance metadata.

    If there is no base image, all fields are set to None.
    """,
    fields = [
        "metadata",
        "image",
    ],
)

def _base_image_metadata_aspect_impl(target, ctx):
    def assert_single(elems, tpe):
        if len(elems) == 1:
            return elems[0]

        fail("expected exactly one ", tpe, " in ", target.label)

    if target.label.repo_name != "":
        # We've left the root repository. This is the external base image.
        # We assume it is from rules_oci and simply retrieve the package_metadata.
        # If it is not correct, we'll fail later.
        metadatas = [
            t[PackageMetadataInfo].metadata
            for t in ctx.rule.attr.package_metadata
            if PackageMetadataInfo in t
        ]

        return [_BaseImageMetadataInfo(
            metadata = assert_single(metadatas, "package_metadata"),
            image = assert_single(target[DefaultInfo].files.to_list(), "file"),
        )]

    if not hasattr(ctx.rule.attr, "base"):
        fail("target without 'base' attribute in OCI image ancestry chain: ", target.label)

    if ctx.rule.attr.base == None:
        # No base image.
        return [_BaseImageMetadataInfo(metadata = None, image = None)]

    # Forward base image info.
    return [ctx.rule.attr.base[_BaseImageMetadataInfo]]

_base_image_metadata_aspect = aspect(
    doc = "Aspect to follow the `base` attribute of oci_image until we find package_metadata",
    implementation = _base_image_metadata_aspect_impl,
    apply_to_generating_rules = True,
    attr_aspects = ["base"],
)

def _image_annotations_impl(ctx):
    inputs = []

    args = ctx.actions.args()
    args.add("--output", ctx.outputs.annotations)

    base_info = ctx.attr.image[_BaseImageMetadataInfo]

    if base_info.metadata != None:
        inputs.append(base_info.metadata)
        inputs.append(base_info.image)  # `.image` implied not None by invariant.

        args.add("--baseMetadataFile", base_info.metadata)
        args.add("--baseImage", base_info.image.path)

    stamp = maybe_stamp(ctx)

    if stamp:
        inputs.append(stamp.stable_status_file)
        inputs.append(stamp.volatile_status_file)

        args.add("--stableStatusFile", stamp.stable_status_file)
        args.add("--volatileStatusFile", stamp.volatile_status_file)

    ctx.actions.run(
        outputs = [ctx.outputs.annotations],
        inputs = inputs,
        arguments = [args],
        env = {"BAZEL_BINDIR": "."},
        executable = ctx.executable._builder,
    )

image_annotations = rule(
    doc = """Creates annotations to pass to oci_image.""",
    implementation = _image_annotations_impl,
    attrs = dict({
        "annotations": attr.output(
            doc = """Output file containing the annotations to apply to the OCI image.""",
            mandatory = True,
        ),
        "image": attr.label(
            aspects = [_base_image_metadata_aspect],
            mandatory = True,
        ),
        "_builder": attr.label(
            default = Label("//private/docker/publish/src:image-annotations"),
            executable = True,
            cfg = "exec",
        ),
    }, **STAMP_ATTRS),
)
