"""Typescript compilation and linting rules."""

load("//private/ts:js_binary.bzl", _js_binary = "js_binary")
load("//private/ts:library.bzl", _ts_default_srcs = "ts_default_srcs", _ts_library = "ts_library")
load("//private/ts:test.bzl", _ts_test = "ts_test")

ts_library = _ts_library
ts_test = _ts_test
ts_default_srcs = _ts_default_srcs
js_binary = _js_binary
