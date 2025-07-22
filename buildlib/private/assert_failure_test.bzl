"""Utility rule to test analysis failure"""

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")

def _assert_failure_test_impl(ctx):
    env = analysistest.begin(ctx)
    asserts.expect_failure(env, ctx.attr.expected_failure)
    return analysistest.end(env)

assert_failure_test = analysistest.make(
    _assert_failure_test_impl,
    expect_failure = True,
    attrs = {
        "expected_failure": attr.string(),
    },
)
