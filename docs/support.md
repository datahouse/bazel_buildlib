# Versioning and Support policy

it-bazel / dh_buildlib uses [Semantic Versioning](https://semver.org/) to version its releases.

The public API is documented in the [dh_buildlib README.md](../buildlib/README.md).

## Supported Versions

Versions are supported for whichever is shorter:

- 2 weeks after release of the next minor or patch version.
- 1 month after release of the next major version.

Other versions are not supported. Notably, there is no guarantee that they can
be built with the newest version of
[it-drone-bazel](https://git.datahouse.ch/datahouse/it-drone-bazel).

It is strongly suggested to use Renovate to keep dh_buildlib up to date.

## Non-Breaking Changes

The following type of changes are explicitly not considered backward
incompatible and hence will not trigger a major version bump. However, a minor
version bump is required for such changes.

- Changes that require installing new npm packages.

  Rationale: It's very easy to fix downstream.

- Changes that require updating automated files (including automated re-formatting).

  Rationale: It's very easy to fix downstream.

- Changes to eslint rules (even more restrictive ones).

  Rationale: Projects can temporarily re-configure problematic changes locally.

- Changes requiring automatically validated updates to Renovate config.

  Rationale: It's very easy to fix downstream.

- Removal of transitive bazel dependencies.

  Rationale: Artifact of not having moved to bzlmod
  (https://git.datahouse.ch/datahouse/it-bazel/issues/5), will become a non-issue.
