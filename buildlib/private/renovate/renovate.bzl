"""Rules for renovate"""

load("@aspect_rules_js//js:defs.bzl", "js_test")
load("@aspect_rules_js//npm:repositories.bzl", "LATEST_PNPM_VERSION")

def renovate_config(name, src):
    """Checks a renovate config for consistency.

    Example: [`@examples//:renovate`](../../examples/BUILD.bazel#:~:text=name%20%3D%20%22renovate%22%2C)

    Args:
      name: Rule name. Should be "renovate".
      src: Renovate config (`renovate.json` or `renovate.json5`).
    """

    js_test(
        name = name,
        args = [
            "--renovate-config",
            "$(location %s)" % src,
            "--pnpm-version",
            LATEST_PNPM_VERSION,
        ],
        data = [Label("//private/renovate/src"), src],
        entry_point = Label("//private/renovate/src:check-renovate-config.js"),
    )
