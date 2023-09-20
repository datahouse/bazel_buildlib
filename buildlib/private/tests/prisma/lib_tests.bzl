"""Unit tests for lib.bzl."""

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts", "unittest")
load("//private/prisma:lib.bzl", "parse_distro")

#######################################################################
#######  test parse_distro(os_release_input) with a valid data  #######
#######################################################################
def _parse_distro_test_impl(ctx):
    env = unittest.begin(ctx)
    asserts.equals(env, ctx.attr.expected_distro, parse_distro(ctx.attr.os_releases))
    return unittest.end(env)

_parse_distro_test = unittest.make(
    _parse_distro_test_impl,
    attrs = {
        "expected_distro": attr.string(),
        "os_releases": attr.string(),
    },
)

########################################################################
#######  test fail condition for parse_distro(os_release_input)  #######
########################################################################
def _parse_distro_rule_impl(ctx):
    parse_distro(ctx.attr.os_releases)

_parse_distro_rule = rule(
    implementation = _parse_distro_rule_impl,
    attrs = {
        "os_releases": attr.string(),
    },
)

def _assert_failure_test_impl(ctx):
    env = analysistest.begin(ctx)
    asserts.expect_failure(env, ctx.attr.expected_failure)
    return analysistest.end(env)

_assert_failure_test = analysistest.make(
    _assert_failure_test_impl,
    expect_failure = True,
    attrs = {
        "expected_failure": attr.string(),
    },
)

def _parse_distro_fail_test(name, os_releases, expected_failure):
    _parse_distro_rule(
        name = name + ".parse",
        os_releases = os_releases,
        tags = ["manual"],
    )

    _assert_failure_test(
        name = name,
        expected_failure = expected_failure,
        target_under_test = name + ".parse",
    )

########################################
#######  test suite for lib.bzl  #######
########################################
def lib_test_suite(name):
    """Test suite

    Args:
      name: Name of this rule.
    """

    _parse_distro_test(
        name = name + "_ubuntu",
        expected_distro = "debian",
        os_releases = """
PRETTY_NAME="Ubuntu 22.04.1 LTS"
NAME="Ubuntu"
VERSION_ID="22.04"
VERSION="22.04.1 LTS (Jammy Jellyfish)"
VERSION_CODENAME=jammy
ID_LIKE=debian
ID=ubuntu
""",
    )

    _parse_distro_test(
        name = name + "_pop",
        expected_distro = "debian",
        os_releases = """
NAME="Pop!_OS"
VERSION="22.04 LTS"
ID=pop
ID_LIKE="ubuntu debian"
PRETTY_NAME="Pop!_OS 22.04 LTS"
""",
    )

    _parse_distro_test(
        name = name + "_only_id_like",
        expected_distro = "debian",
        os_releases = "ID_LIKE=debian",
    )

    _parse_distro_test(
        name = name + "_id_takes_precedence",
        expected_distro = "musl",
        os_releases = """
ID_LIKE=debian
ID=alpine
""",
    )

    # Test an edge case where the first distro is not in the map
    _parse_distro_test(
        name = name + "_only_second_distro_valid",
        expected_distro = "debian",
        os_releases = """
ID=unknown
ID_LIKE="unknown debian"
""",
    )

    _parse_distro_fail_test(
        name = name + "_no_id",
        os_releases = """
FOO=bar
""",
        expected_failure = "couldn't find ID= or ID_LIKE= line in /etc/os-release",
    )

    _parse_distro_fail_test(
        name = name + "_unknown_distro",
        os_releases = """
ID=foo
ID_LIKE="bar baz"
""",
        expected_failure = "unknown linux distribution 'ID=foo; ID_LIKE=\"bar baz\"'",
    )
