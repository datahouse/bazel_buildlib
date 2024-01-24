"""Rule to load a docker image into the local docker daemon from within a TS test."""

load("@aspect_bazel_lib//lib:copy_file.bzl", "COPY_FILE_TOOLCHAINS", "copy_file_action")
load("@aspect_rules_js//js:defs.bzl", "js_library")
load("@bazel_skylib//lib:paths.bzl", "paths")

def _loader_impl(ctx):
    js_dir = paths.dirname(ctx.outputs.js.short_path)
    workspace_rel_path = paths.join(*[".." for _ in js_dir.split("/")])

    ctx.actions.expand_template(
        output = ctx.outputs.js,
        template = ctx.file._js_tpl,
        substitutions = {
            "{{ IMAGE }}": ctx.file.image.short_path,
            "{{ LIB }}": paths.join(workspace_rel_path, ctx.file._lib.short_path),
        },
    )

    copy_file_action(ctx, ctx.file._decl, ctx.outputs.decl)

_loader = rule(
    implementation = _loader_impl,
    attrs = {
        "decl": attr.output(),
        "image": attr.label(
            allow_single_file = True,
        ),
        "js": attr.output(),
        "_decl": attr.label(
            allow_single_file = True,
            default = Label("//private/docker:load-image-for-ts-test.d.ts"),
        ),
        "_js_tpl": attr.label(
            allow_single_file = True,
            default = Label("//private/docker:load-image-for-ts-test.tpl.js"),
        ),
        "_lib": attr.label(
            allow_single_file = True,
            default = Label("//private/docker/src:loadImageToDocker.js"),
        ),
    },
    toolchains = COPY_FILE_TOOLCHAINS,
)

def docker_image_for_ts_test(name, image, visibility = None):
    """Prepares a docker image to be loaded in a TS test.

    Typically, this is for use with testcontainers.

    For example, say you have the following in your BUILD.bazel:

    ```BUILD
    docker_image_for_ts_test(
      name = "load_my_image",
      image = "//path/to/my:image",
    )

    ts_test(
      name = "test"
      deps = [":load_my_image"],
    )
    ```

    Now inside your test, you can:

    ```ts
    import { GenericContainer } from "testcontainers";
    import loadMyImage from "./load_my_image.js";

    test("my test", async () => {
      // This will load the image into the local docker daemon
      // and return a reference you can use with testcontainers.
      const image = await loadMyImage();

      const container = await new GenericContainer(image).start();
    });
    ```

    Note: This rule can only be used for tests.

    Example: [`@examples//prisma/test:load_postgres_image`](../../examples/prisma/test/BUILD.bazel#:~:text=name%20%3D%20%22load_postgres_image%22%2C)

    Args:
      name: Name of the rule and the generated JS file.
      image: The docker image to load.
      visibility: Visibility specification.
    """

    _loader(
        name = name + ".loader",
        js = name + ".js",
        decl = name + ".d.ts",
        image = image,
        testonly = True,
    )

    js_library(
        name = name,
        srcs = [name + ".js"],
        declarations = [name + ".d.ts"],
        data = [image],
        deps = [Label("//private/docker/src")],
        testonly = True,
        visibility = visibility,
    )
