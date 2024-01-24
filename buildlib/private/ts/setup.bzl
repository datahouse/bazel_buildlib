"""Utiliy macro for Typescript setup."""

load(":config.bzl", "tsconfig_base")
load(":eslintrc.bzl", "eslintrc")
load(":pnpm_lock_test.bzl", "pnpm_lock_test")

def ts_setup(name):
    """
    Utility macro to reduce boilerplate for JavaScript / Typescript setup.

    Example: [`@examples//:ts_setup`](../../examples/BUILD.bazel#:~:text=name%20%3D%20%22ts_setup%22%2C)

    Strictly equivalent to (but this may evolve over time):

    ```
    tsconfig_base(
        name = "tsconfig-base",
        visibility = ["//:__subpackages__"],
    )

    eslintrc(
        name = "eslintrc",
        visibility = ["//:__subpackages__"],
    )

    pnpm_lock_test(
        name = "pnpm_lock_test",
    )
    ```

    Args:
      name: Dummy name argument (for tool support / rule shape). Must be `ts_setup`.
    """

    if name != "ts_setup" or native.package_name() != "":
        fail("ts_setup must be at //:ts_setup")

    tsconfig_base(
        name = "tsconfig-base",
        visibility = ["//:__subpackages__"],
    )

    eslintrc(
        name = "eslintrc",
        visibility = ["//:__subpackages__"],
    )

    pnpm_lock_test(
        name = "pnpm_lock_test",
    )
