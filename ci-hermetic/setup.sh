#! /bin/sh

cat ci-hermetic/bazelrc-additions >> $1/project.bazelrc
cp ci-hermetic/*.patch $1
cat ci-hermetic/MODULE-additions >> $1/MODULE.bazel
