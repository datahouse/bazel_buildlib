"""Test to check pnpm lock consistency."""

def pnpm_lock_test(name):
    """Tests that package.json and pnpm-lock.yaml are in sync.

    Both of these files are implicitly depended upon.

    Examples:
    - See [`ts_setup`](#ts_setup)
    - [`@buildlib//private:pnpm_lock_test`](../private/BUILD.bazel#:~:text=name%20%3D%20%22pnpm_lock_test%22%2C)

    Args:
      name: Name of the test (suggested: `pnpm_lock_test`).
    """

    native.sh_test(
        name = name,
        srcs = [Label(":test-pnpm-lock.sh")],
        env = {
            "PNPM_BIN": "$(rootpath @pnpm)",
            "PNPM_RELPATH": native.package_name(),
        },
        data = ["@pnpm", "package.json", "pnpm-lock.yaml"],
    )
