"""Typescript compilation and linting rules."""

load("//private/ts:json_to_ts.bzl", _json_to_ts = "json_to_ts")
load("//private/ts:library.bzl", _ts_library = "ts_library")
load("//private/ts:test.bzl", _ts_test = "ts_test")

ts_library = _ts_library
ts_test = _ts_test
json_to_ts = _json_to_ts
