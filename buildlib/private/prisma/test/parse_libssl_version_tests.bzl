"""Unit tests for parse_lib_ssl_version in lib.bzl."""

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts", "unittest")
load("//private/prisma:lib.bzl", "parse_lib_ssl_version")

#############################################################
#######  test parse_lib_ssl_version with a valid data #######
#############################################################

def _parse_lib_ssl_version_test_impl(ctx):
    env = unittest.begin(ctx)
    asserts.equals(env, ctx.attr.expect, parse_lib_ssl_version(ctx.attr.input))
    return unittest.end(env)

_parse_lib_ssl_version_test = unittest.make(
    _parse_lib_ssl_version_test_impl,
    attrs = {
        "expect": attr.string(),
        "input": attr.string(),
    },
)

#######################################################
#######  test failures of parse_lib_ssl_version #######
#######################################################

def _parse_lib_ssl_version_rule_impl(ctx):
    parse_lib_ssl_version(ctx.attr.input)

_parse_lib_ssl_version_rule = rule(
    implementation = _parse_lib_ssl_version_rule_impl,
    attrs = {
        "input": attr.string(),
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

def _parse_lib_ssl_version_fail_test(name, input, expected_failure):
    _parse_lib_ssl_version_rule(
        name = name + ".parse",
        input = input,
        tags = ["manual"],
    )

    _assert_failure_test(
        name = name,
        expected_failure = expected_failure,
        target_under_test = name + ".parse",
    )

########################################
#######  test suite              #######
########################################

def parse_lib_ssl_version_test_suite(name):
    """Test suite

    Args:
      name: Name prefix of tests.

    Origin:
    https://github.com/prisma/prisma/blob/cddc868597386278c35878d96168cbf14f7eb5da/packages/get-platform/src/__tests__/parseOpenSSLVersion.test.ts#L48C1-L116
    """

    _parse_lib_ssl_version_test(
        name = name + "_1.0",
        input = "libssl.so.1",
        expect = "1.0",
    )

    _parse_lib_ssl_version_test(
        name = name + "_1.0.2k",
        input = "libssl.so.1.0.2k",
        expect = "1.0",
    )

    _parse_lib_ssl_version_test(
        name = name + "_10",
        input = "libssl.so.10",
        expect = "1.0",
    )

    _parse_lib_ssl_version_test(
        name = name + "_1.1",
        input = "libssl.so.1.1",
        expect = "1.1",
    )

    _parse_lib_ssl_version_test(
        name = name + "_1.1.1",
        input = "libssl.so.1.1.1",
        expect = "1.1",
    )

    _parse_lib_ssl_version_test(
        name = name + "_1.1.1g",
        input = "libssl.so.1.1.1g",
        expect = "1.1",
    )

    _parse_lib_ssl_version_test(
        name = name + "_3",
        input = "libssl.so.3",
        expect = "3",
    )

    _parse_lib_ssl_version_test(
        name = name + "_3.1",
        input = "libssl.so.3.1",
        expect = "3",
    )

    _parse_lib_ssl_version_fail_test(
        name = name + "_0.9.8_unsupported",
        input = "libssl.so.0.9.8",
        expected_failure = "openssl 0 is not supported",
    )

    _parse_lib_ssl_version_fail_test(
        name = name + "_2_unsupported",
        input = "libssl.so.2",
        expected_failure = "openssl 2 is not supported",
    )

    _parse_lib_ssl_version_fail_test(
        name = name + "_4_unsupported",
        input = "libssl.so.4",
        expected_failure = "openssl 4 is not supported",
    )

    _parse_lib_ssl_version_fail_test(
        name = name + "_ignore_libssl3",
        input = "libssl3.so",
        expected_failure = "unexpected input: libssl3.so",
    )
