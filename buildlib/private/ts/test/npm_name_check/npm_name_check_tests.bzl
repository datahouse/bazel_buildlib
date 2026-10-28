"""Failure tests for npm name validation used in esm_node_modules."""

load("//private:assert_failure_test.bzl", "assert_failure_test")
load("//private/ts:npm_name_check.bzl", "check_is_well_behaved_npm_name")

def _check_npm_name_rule_impl(ctx):
    check_is_well_behaved_npm_name(ctx.attr.pkg_name)

_check_npm_name_rule = rule(
    implementation = _check_npm_name_rule_impl,
    attrs = {
        "pkg_name": attr.string(),
    },
)

def _npm_name_fail_test(name, pkg_name, expected_failure):
    _check_npm_name_rule(
        name = name + ".check",
        pkg_name = pkg_name,
        tags = ["manual"],
    )

    assert_failure_test(
        name = name,
        expected_failure = expected_failure,
        target_under_test = name + ".check",
    )

_EXPECTED_FAILURE = "is not a well-behaved npm package name."

def npm_name_check_test_suite(name):
    """Failure tests for npm name validation used in esm_node_modules.

    Args:
      name: Name of this rule.
    """

    _npm_name_fail_test(
        name = name + "_empty",
        pkg_name = "",
        expected_failure = _EXPECTED_FAILURE,
    )

    _npm_name_fail_test(
        name = name + "_uppercase",
        pkg_name = "UPPERCASE",
        expected_failure = _EXPECTED_FAILURE,
    )

    _npm_name_fail_test(
        name = name + "_has_spaces",
        pkg_name = "has spaces",
        expected_failure = _EXPECTED_FAILURE,
    )

    _npm_name_fail_test(
        name = name + "_starts_with_dot",
        pkg_name = ".hidden",
        expected_failure = _EXPECTED_FAILURE,
    )

    _npm_name_fail_test(
        name = name + "_starts_with_hyphen",
        pkg_name = "-bad",
        expected_failure = _EXPECTED_FAILURE,
    )

    _npm_name_fail_test(
        name = name + "_scoped_no_slash",
        pkg_name = "@noslash",
        expected_failure = _EXPECTED_FAILURE,
    )

    _npm_name_fail_test(
        name = name + "_special_chars",
        pkg_name = "pkg!name",
        expected_failure = _EXPECTED_FAILURE,
    )

    _npm_name_fail_test(
        name = name + "_exceeds_max_length",
        pkg_name = "a" * 121,
        expected_failure = _EXPECTED_FAILURE,
    )
