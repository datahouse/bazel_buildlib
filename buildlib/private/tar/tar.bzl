"""Convenience rules / macros for tars."""

load("@aspect_bazel_lib//lib:tar.bzl", "tar", _core_mtree_spec = "mtree_spec")

def _mtree_replace_prefix_impl(ctx):
    out = ctx.outputs.out or ctx.actions.declare_file(ctx.attr.name + ".spec")

    ctx.actions.run(
        inputs = [ctx.file.src],
        outputs = [out],
        executable = ctx.executable._tool,
        arguments = [
            "--src",
            ctx.file.src.path,
            "--out",
            out.path,
            "--prefix",
            ctx.attr.prefix,
            "--replacement",
            ctx.attr.replacement,
        ],
        env = {
            "BAZEL_BINDIR": ".",
        },
    )

    return DefaultInfo(files = depset([out]))

mtree_replace_prefix = rule(
    doc = """Modifies target paths in an mtree spec.

    For entries that start with `prefix`: Removes and (optionally) replaces the prefix.
    Drops entries that do not start with `prefix`.
    """,
    implementation = _mtree_replace_prefix_impl,
    attrs = {
        "out": attr.output(
            doc = "The transformed mtree file",
        ),
        "prefix": attr.string(
            doc = "The prefix to remove",
            mandatory = True,
        ),
        "replacement": attr.string(
            doc = "Replacement for the prefix",
            default = "",
        ),
        "src": attr.label(
            doc = "The mtree file to transform",
            mandatory = True,
            allow_single_file = True,
        ),
        "_tool": attr.label(
            default = Label("//private/tar/src:mtree-replace-prefix"),
            executable = True,
            cfg = "exec",
        ),
    },
)

def mtree_spec(name, srcs, strip_prefix = None, replace_prefix = None, out = None, visibility = None, testonly = None):
    """Convenience macro to invoke mtree_spec with strip_refix functionality.

    Strictly equivalent to calling aspect_bazel_lib's mtree_spec followed by `mtree_replace_prefix`.

    Args:
      name: Name of the final target.
      srcs: Sources to include in the mtree.
      strip_prefix: `prefix` argument to mtree_replace_prefix.
      replace_prefix: `replacement` argument to mtree_replace_prefix.
      out: Output file.
      visibility: Visibility specifier.
      testonly: Testonly flag.
    """

    if strip_prefix == None:
        if replace_prefix != None:
            fail("you cannot set replace_prefix without setting strip_prefix")

        _core_mtree_spec(
            name = name,
            srcs = srcs,
            out = out,
            visibility = visibility,
            testonly = testonly,
        )
    else:
        _core_mtree_spec(
            name = name + ".raw",
            srcs = srcs,
            testonly = testonly,
        )

        mtree_replace_prefix(
            name = name,
            src = name + ".raw",
            out = out,
            prefix = strip_prefix,
            replacement = replace_prefix,
            visibility = visibility,
            testonly = testonly,
        )

def tar_auto_mtree(name, srcs, args = [], compress = None, strip_prefix = None, replace_prefix = None, out = None, visibility = None, testonly = None):
    """Convenience macro to invoke tar with auto mtree with strip_refix functionality.

    Strictly equivalent to calling (dh_buildlib) mtree_spec follwed by aspect_bazel_lib's tar.

    Args:
      name: Name of the final target.
      srcs: Sources to include in the tar.
      args: Passed to tar.
      compress: Passed to tar.
      strip_prefix: `prefix` argument to mtree_replace_prefix.
      replace_prefix: `replacement` argument to mtree_replace_prefix.
      out: Output file.
      visibility: Visibility specifier.
      testonly: Testonly flag.
    """

    mtree_spec(
        name = name + ".mtree",
        srcs = srcs,
        strip_prefix = strip_prefix,
        replace_prefix = replace_prefix,
        testonly = testonly,
    )

    tar(
        name = name,
        srcs = srcs,
        mtree = name + ".mtree",
        args = args,
        compress = compress,
        out = out,
        visibility = visibility,
        testonly = testonly,
    )
