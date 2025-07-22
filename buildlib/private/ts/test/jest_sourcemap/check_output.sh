#! /bin/sh

set -ex

# Check we are testing the .js file (but not the .ts file).
grep -F 'FAIL private/ts/test/jest_sourcemap/failing.test.js' $1
grep -F 'FAIL private/ts/test/jest_sourcemap/failing.test.ts' $1 && exit 1 # invert condition under set -e

# Check source mapping can resolve the location
grep -F 'failing.test.ts:5:22' $1

# Check jest can find the original source code.
grep -F 'expect(1 as const).toEqual(0);' $1
