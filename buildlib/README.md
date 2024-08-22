# dh_buildlib

This is the bazel library underlying the Datahouse build core.

It is designed to work together with the
[Datahouse Drone Bazel plugin](https://git.datahouse.ch/datahouse/it-drone-bazel).

## API Docs

Starlark APIs provided by dh_buildlib.

- Typescript
  - [ts.md](./docs/ts.md): rules for core Typescript (compiling, testing, linting)
  - [ts_docker.md](./docs/ts_docker.md): rules for Typescript in/on Docker
  - [ts_setup.md](./docs/ts_setup.md): rules to set up the JavaScript / Typescript base system
- [docker.md](./docs/docker.md): Docker and docker compose related rules
- GraphQL
  - [gql_ts.md](./docs/ts_gql.md): GQL integration for Typescript (client and server)
- [prisma.md](./docs/prisma.md): Prisma related rules
- [react_app.md](./docs/react_app.md): rule to create React apps
- Tooling
  - [format.md](./docs/format.md): rules for formatting
  - [bazelrc.md](./docs/bazelrc.md): rules for bazelrc management
  - [renovate.md](./docs/renovate.md): rules to help with Renovate configuration
  - [tar.md](./docs/tar.md): convenience rules for tars

## Build Targets

Build targets provided by dh_buildlib.[^1]

<!-- use `git grep visibility:public` as a first approximation to find if these are up-to-date. -->

### My Version

Build targets providing access to the build's version (when building a tag).

- `@dh_buildlib//my-version:txt`: A txt file containing the version.
- `@dh_buildlib//my-version:json`: A json file containing the version (as a sole string).
- `@dh_buildlib//my-version:ts`: A TypeScript file with a single default export: the version as string.

### Prisma Contraints

Bazel constraint packages for relevant platform parameters to resolve the Prisma engine.

- [`@dh_buildlib//prisma/linux`](./prisma/linux/BUILD.bazel): Linux flavor
- [`@dh_buildlib//prisma/openssl`](./prisma/openssl/BUILD.bazel): OpenSSL version

[^1]:
    targets containing `private` in their package path / name are implementation
    details and subject to change at any time (even if they have public visibility).
