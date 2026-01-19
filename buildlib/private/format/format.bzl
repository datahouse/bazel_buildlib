"""Rules to run formatters / test formatting."""

load("@aspect_rules_js//js:defs.bzl", "js_binary")
load("@rules_java//java:java_binary.bzl", "java_binary")
load("@rules_python//python/entry_points:py_console_script_binary.bzl", "py_console_script_binary")
load("@rules_shell//shell:sh_test.bzl", "sh_test")
load("//private:npm_js_binary.bzl", "npm_js_binary")

def _format_impl(name, bazelrc, format_java, format_py, visibility):
    data = [
        Label("//private/format/src"),
    ]

    env = {
        "BAZEL_BINDIR": ".",
    }

    def add_formatter(name, label):
        data.append(label)
        env[name + "_BIN"] = "$(rootpath %s)" % label

    add_formatter("BUILDIFIER", Label("@buildifier_prebuilt//:buildifier"))

    npm_js_binary(
        name = name + ".prettier",
        entry_point = "./bin/prettier.cjs",
        node_module = "prettier",
    )

    add_formatter("PRETTIER", name + ".prettier")

    if format_java:
        java_binary(
            name = name + ".google_java_format",
            # Flags required for google-java-format. See:
            # https://github.com/google/google-java-format?tab=readme-ov-file#as-a-library
            jvm_flags = [
                "--add-exports=jdk.compiler/com.sun.tools.javac.api=ALL-UNNAMED",
                "--add-exports=jdk.compiler/com.sun.tools.javac.code=ALL-UNNAMED",
                "--add-exports=jdk.compiler/com.sun.tools.javac.file=ALL-UNNAMED",
                "--add-exports=jdk.compiler/com.sun.tools.javac.parser=ALL-UNNAMED",
                "--add-exports=jdk.compiler/com.sun.tools.javac.tree=ALL-UNNAMED",
                "--add-exports=jdk.compiler/com.sun.tools.javac.util=ALL-UNNAMED",
            ],
            main_class = "com.google.googlejavaformat.java.Main",
            runtime_deps = [
                "@maven//:com_google_googlejavaformat_google_java_format",
            ],
        )

        add_formatter("GOOGLE_JAVA_FORMAT", name + ".google_java_format")

    if format_py:
        py_console_script_binary(
            name = name + ".black",
            pkg = "@pypi//black",
            script = "black",
        )

        add_formatter("BLACK", name + ".black")

    js_binary(
        name = name,
        data = data,
        copy_data_to_bin = False,
        entry_point = Label("//private/format/src:format.js"),
        env = env,
        visibility = visibility,
    )

    sh_test(
        name = name + ".test",
        srcs = [Label(":format-test.sh")],
        data = [name, "//:.bazelrc"],
        env = {
            "DH_FORMAT_SCRIPT": "$(rootpath %s)" % name,
            # Pass any file in the workspace root to determine its locaiton.
            "FILE_IN_WORKSPACE": "$(location %s)" % bazelrc,
        },
        tags = ["local", "external"],
    )

format = macro(
    attrs = {
        "bazelrc": attr.label(
            doc = "bazelrc file to determine the workspace root",
            mandatory = True,
            allow_single_file = True,
            configurable = False,
        ),
        "format_java": attr.bool(
            doc = "whether to format java",
            mandatory = True,
            configurable = False,
        ),
        "format_py": attr.bool(
            doc = "whether to format python",
            mandatory = True,
            configurable = False,
        ),
    },
    implementation = _format_impl,
)
