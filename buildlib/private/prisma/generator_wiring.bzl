"""Prisma generator wiring rules (internal)."""

load("@aspect_rules_js//js:providers.bzl", "JsInfo")
load("//private/prisma:providers.bzl", "PrismaGenerateInfo", "PrismaGeneratorInfo")

def _get_target_name(ctx, suffix):
    name = ctx.label.name
    if not name.endswith(suffix):
        fail("rule name needs to end in %s" % suffix)

    return name.removesuffix(suffix)

def _prisma_generator_def_impl(ctx):
    return PrismaGeneratorInfo(
        target_name = _get_target_name(ctx, ".generator"),
        generate_deps = ctx.attr.deps,
        module_type = ctx.attr.module_type,
        exec_paths = ctx.attr.exec_paths,
    )

prisma_generator_def = rule(
    doc = "Glue rule to provide prisma generator info",
    attrs = {
        "deps": attr.label_list(
            providers = [JsInfo],
            default = [],
        ),
        "exec_paths": attr.string_list(
            default = [],
        ),
        "module_type": attr.string(
            values = ["module", "commonjs"],
            mandatory = True,
        ),
    },
    implementation = _prisma_generator_def_impl,
)

def _prisma_generator_result_impl(ctx):
    target_name = _get_target_name(ctx, ".result")

    info = ctx.attr.generate[PrismaGenerateInfo]

    out_dir = info.out_dirs.get(target_name)
    if not out_dir:
        fail("Did not find '{0}' in results of {1}. Did you add ':{0}.generator' to the 'generators' attribute?".format(
            target_name,
            ctx.attr.generate.label,
        ))

    return DefaultInfo(files = depset([out_dir]))

prisma_generator_result = rule(
    doc = "Glue rule to extract prisma generator result",
    attrs = {
        "generate": attr.label(
            providers = [PrismaGenerateInfo],
        ),
    },
    implementation = _prisma_generator_result_impl,
)
