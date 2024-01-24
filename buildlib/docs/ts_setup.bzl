"""Rules to set up the JavaScript / Typescript base system.

For a typical project, it is best to just use [`ts_setup`](#ts_setup) which
instantiates all the other rules.

However, the individual rules are also provided, in case more fine grained
control is needed.
"""

load("//private/ts:config.bzl", _tsconfig_base = "tsconfig_base")
load("//private/ts:eslintrc.bzl", _eslintrc = "eslintrc")
load("//private/ts:pnpm_lock_test.bzl", _pnpm_lock_test = "pnpm_lock_test")
load("//private/ts:setup.bzl", _ts_setup = "ts_setup")

ts_setup = _ts_setup
eslintrc = _eslintrc
tsconfig_base = _tsconfig_base
pnpm_lock_test = _pnpm_lock_test
