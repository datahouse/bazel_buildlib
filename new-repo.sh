#! /bin/sh

set -e

REPO="$(realpath "$(dirname "$0")")"

fail () { echo "$1"; exit 1; }

# Check arguments
[ -n "$1" ] || fail "usage: $(basename "$0") DIRECTORY "
[ ! -e "$1" ] || fail "$1 already exists"

# Check required tools are available.
which bazelisk > /dev/null || fail "you must install bazelisk"
which git > /dev/null || fail "you must install git"

# Fetch tags to make sure they are up to date.
( cd "$REPO" && git fetch --tags git@git.datahouse.ch:datahouse/it-bazel.git )

# Initialize git repo
# Explicitly set branch name so it is the same independent of the git version.
git init --initial-branch=main "$1" && cd "$1"

## Copy templates.
cp "$REPO/examples/.bazelversion" .
cp "$REPO/examples/.bazelignore" .
cp "$REPO/examples/.npmrc" .
cp "$REPO/examples/.nvmrc" .

cp "$REPO/new-repo/templates/.prettierignore" .
cp "$REPO/new-repo/templates/.gitignore" .
cp "$REPO/new-repo/templates/.eslintrc.js" .
cp "$REPO/new-repo/templates/BUILD.bazel" .
cp "$REPO/new-repo/templates/.drone.yml" .

# Get newest buildlib tag
LIB_TAG="$(cd "$REPO" && git describe --tags --abbrev=0)"

# Get SHA for that tag.
LIB_SHA="$(cd "$REPO" && git rev-list -n 1 "$LIB_TAG")"

sed "s/{{ BUILDLIB_SHA }}/$LIB_SHA/;s/{{ BUILDLIB_TAG }}/$LIB_TAG/" "$REPO/new-repo/templates/WORKSPACE" > WORKSPACE

# Bootstrap pnpm
echo "{}" > package.json
touch pnpm-lock.yaml
bazelisk run @pnpm -- install --dir="$PWD" --fix-lockfile

# Write boilerplate
bazelisk run //:bazelrc
bazelisk run //:tsconfig-base.write

# Install typescript
bazelisk run @pnpm -- install --dir="$PWD" --save-dev --save-exact typescript --lockfile-only

# Test installation
bazelisk build //...
bazelisk test //...

# Commit
git add .
git commit -m 'Initial it-bazel setup'

echo "✅ new Datahouse repository is set up. Happy hacking ‍💻"
