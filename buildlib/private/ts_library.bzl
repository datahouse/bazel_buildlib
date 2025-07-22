"""ts_library / ts_test forwarder with our private tsc repository."""

load("//ts:defs.bzl", _ts_library = "ts_library", _ts_test = "ts_test")

def ts_library(**kwargs):
    _ts_library(
        tsc_repository = "@dh_buildlib_private_typescript",
        **kwargs
    )

def ts_test(**kwargs):
    _ts_test(
        tsc_repository = "@dh_buildlib_private_typescript",
        **kwargs
    )
