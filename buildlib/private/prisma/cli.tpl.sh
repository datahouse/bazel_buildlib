#! /bin/sh

export RUNFILES_DIR=${RUNFILES_DIR:-"$0.runfiles"}

{{PRISMA_ENGINE_EXPORTS}}

# BUILD_ID is automatically set by bazel 9 in run commands.
# However, prisma interprets it as isCI and fails if user interaction
# (e.g. confirmation) is required (#1681).
#
# Since we do not need BUILD_ID, we simply unset it here.
# (this is also used for non-run usage but unsetting does not hurt).
#
# See:
# - Prisma isCI detection:
#   https://github.com/prisma/prisma/blob/9fa295d70ff0497e0f0e4f06bdd5df76f6a9501a/packages/internals/src/utils/isCi.ts#L53
# - Introducing bazel commit:
#   https://cs.opensource.google/bazel/bazel/+/779d6976f8fe23e1306333022e3fd27764aeb09f
# - Relevant bit in bazel 9 release notes:
#   https://github.com/bazelbuild/bazel/releases/tag/9.0.0#:~:text=Commands%20executed%20by%20%22bazel%20run%22%20now%20have%20two%20extra%20environment%20variables%3A%20%24BUILD_ID%20indicates%20the%20id%20of%20the%20Bazel%20command%20and%20%24BUILD_EXECROOT%20indicates%20the%20execroot%20of%20the%20Bazel%20server
unset BUILD_ID

exec "${RUNFILES_DIR}/{{PRISMA_BIN}}" "$@"
