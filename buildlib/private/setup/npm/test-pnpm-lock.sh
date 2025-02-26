#! /bin/sh

# Make pnpm write its cache/state to a tmp directory rather than the user home.
export XDG_DATA_HOME="$TEST_TMPDIR/data"
export XDG_STATE_HOME="$TEST_TMPDIR/state"
export XDG_CACHE_HOME="$TEST_TMPDIR/cache"

$PNPM_BIN install --dir=$PNPM_RELPATH --frozen-lockfile --lockfile-only
