"""package_json rule."""

load("@aspect_rules_js//js:defs.bzl", "js_library", "js_test")

def package_json(name, visibility = []):
    """Declares and validates a package.json file.

    - Must be named `package_json`
    - Implicitly depends on `package.json`

    Args:
      name: Name of the main rule, must be `package_json`
      visibility: Visibility of the main rule.
    """

    if name != "package_json":
        fail("name must be 'package_json'")

    js_library(
        name = name,
        srcs = ["package.json"],
        visibility = visibility,
    )

    js_test(
        name = name + ".test",
        args = ["./package.json"],
        data = [Label("//private/ts/src"), "package.json"],
        entry_point = Label("//private/ts/src:check-package-json.js"),
    )
