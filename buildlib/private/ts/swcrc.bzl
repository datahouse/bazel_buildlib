"""tsconfig rules"""

load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")

_module_type_map = {
    "commonjs": "commonjs",
    "es2020": "es6",
}

# For mapping tsconfig -> swconfig mapping info, have a look at:
# https://www.npmjs.com/package/tsconfig-to-swcconfig
def _swcrc_impl(ctx):
    cfg = {
        "jsc": {
            "keepClassNames": True,
            "parser": {
                "decorators": True,
                "syntax": "typescript",
                "tsx": True,
            },
            "target": "es2018",
            "transform": {
                "decoratorMetadata": True,
                "legacyDecorator": True,
                "react": {
                    "runtime": "automatic",
                },
            },
        },
        "module": {
            "type": _module_type_map[ctx.attr._module_setting[BuildSettingInfo].value],
        },
    }

    ctx.actions.write(
        content = json.encode(cfg),
        output = ctx.outputs.out,
    )

swcrc = rule(
    attrs = {
        "out": attr.output(),
        "_module_setting": attr.label(
            default = Label("//private/ts:module"),
            providers = [BuildSettingInfo],
        ),
    },
    implementation = _swcrc_impl,
)
