"""Rule to load a docker image into the local docker daemon from within a TS test."""

load("@aspect_rules_js//js:defs.bzl", "js_library")
load("@bazel_lib//lib:copy_file.bzl", "copy_file")
load("@bazel_lib//lib:expand_template.bzl", "expand_template")

def _docker_image_for_ts_test_impl(name, image, visibility):
    tool = Label("//private/docker/src:load-image")

    expand_template(
        name = name + ".js_gen",
        out = name + ".js",
        testonly = True,
        template = Label("//private/docker:load-image-for-ts-test.tpl.js"),
        substitutions = {
            "{{ IMAGE }}": "$(rootpath %s)" % image,
            "{{ LOADER }}": "$(rootpath %s)" % tool,
        },
        data = [image, tool],
    )

    copy_file(
        name = name + ".d.ts_gen",
        src = Label("//private/docker:load-image-for-ts-test.d.ts"),
        out = name + ".d.ts",
        testonly = True,
    )

    js_library(
        name = name,
        srcs = [name + ".js"],
        types = [name + ".d.ts"],
        data = [image, tool],
        testonly = True,
        visibility = visibility,
    )

docker_image_for_ts_test = macro(
    doc = """Prepares a docker image to be loaded in a TS test.

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

      await using container = await new GenericContainer(image).start();
    });
    ```

    Note: This rule can only be used for tests.

    Example: [`@examples//prisma/test:load_postgres_image`](../../examples/prisma/test/BUILD.bazel#:~:text=name%20%3D%20%22load_postgres_image%22%2C)
    """,
    attrs = {
        "image": attr.label(
            doc = "The docker image to load.",
            mandatory = True,
            configurable = False,
        ),
    },
    implementation = _docker_image_for_ts_test_impl,
)
