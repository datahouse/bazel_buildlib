"""Rule to load a docker image into the local docker daemon from within a TS test."""

load("@aspect_rules_js//js:defs.bzl", "js_library")
load("@bazel_lib//lib:copy_file.bzl", "copy_file")
load("@bazel_lib//lib:expand_template.bzl", "expand_template")

def _docker_image_for_ts_test_impl(name, image, _lib, _lib_dep, _js_tpl, _types, visibility, testonly):
    expand_template(
        name = name + ".js_gen",
        out = name + ".js",
        testonly = testonly,
        template = _js_tpl,
        substitutions = {
            "{{ IMAGE }}": "$(rlocationpath %s)" % image,
            "{{ LIB }}": "$(rlocationpath %s)" % _lib,
        },
        data = [image, _lib],
    )

    copy_file(
        name = name + ".d.ts_gen",
        src = _types,
        out = name + ".d.ts",
        testonly = testonly,
    )

    js_library(
        name = name,
        srcs = [name + ".js"],
        types = [name + ".d.ts"],
        data = [image, _lib_dep],
        testonly = testonly,
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
      tags = ["requires-docker"]
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

    Note: This rule typically should only be used for tests.

    Example: [`@examples//prisma/test:load_postgres_image`](../../examples/prisma/test/BUILD.bazel#:~:text=name%20%3D%20%22load_postgres_image%22%2C)
    """,
    attrs = {
        "image": attr.label(
            doc = "The docker image to load.",
            mandatory = True,
            configurable = False,
        ),
        "testonly": attr.bool(
            doc = "testonly flag",
            default = True,
            configurable = False,
        ),
        "_js_tpl": attr.label(
            default = "//private/docker/load:load-image-for-ts-test.tpl.js",
            configurable = False,
        ),
        "_lib": attr.label(
            default = "//private/docker/load/src:loadImageDirToDocker.js",
            configurable = False,
        ),
        "_lib_dep": attr.label(
            default = "//private/docker/load/src",
            configurable = False,
        ),
        "_types": attr.label(
            default = "//private/docker/load:load-image-for-ts-test.d.ts",
            configurable = False,
        ),
    },
    implementation = _docker_image_for_ts_test_impl,
)
