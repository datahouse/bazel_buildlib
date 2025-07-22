# dh_buildlib

This is the bazel library underlying the Datahouse build core.

It is designed to work together with the
[Datahouse Drone Bazel plugin](https://git.datahouse.ch/datahouse/it-drone-bazel).

## API Docs

Starlark APIs provided by dh_buildlib.

- Setup
  - [buildlib_setup.md](./docs/buildlib_setup.md): one-stop buildlib setup rule (required).
- Typescript
  - [ts.md](./docs/ts.md): rules for core Typescript (compiling, testing, linting)
  - [ts_docker.md](./docs/ts_docker.md): rules for Typescript in/on Docker
- [docker.md](./docs/docker.md): Docker and docker compose related rules
- GraphQL
  - [gql_ts.md](./docs/gql_ts.md): GQL integration for Typescript (client and server)
- [prisma.md](./docs/prisma.md): Prisma related rules
  - [prisma_generators.md](./docs/prisma_generators.md): Rules for prisma generator providers.
- [react_app.md](./docs/react_app.md): rule to create React apps

## Build Targets

Build targets provided by dh_buildlib.[^1]

<!-- use `git grep visibility:public` as a first approximation to find if these are up-to-date. -->

### My Version

Build targets providing access to the build's version (when building a tag).

- `@dh_buildlib//my-version:txt`: A txt file containing the version.
- `@dh_buildlib//my-version:json`: A json file containing the version (as a sole string).
- `@dh_buildlib//my-version:ts`: A TypeScript file with a single default export: the version as string.
- `@dh_buildlib//my-version:java`: EXPERIMENTAL: A `java_library` target: `import static ch.datahouse.buildlib.myversion.MyVersion.MY_VERSION` for the version string.

### Prisma

#### CLI

- `@dh_buildlib//prisma:cli`: The prisma CLI (with correct prisma engines resolution).

  Requires the `prisma` npm package to be installed as a dev dependency.

#### Constraints

Bazel constraint packages for relevant platform parameters to resolve the Prisma engine.

- [`@dh_buildlib//prisma/linux`](./prisma/linux/BUILD.bazel): Linux flavor
- [`@dh_buildlib//prisma/openssl`](./prisma/openssl/BUILD.bazel): OpenSSL version

[^1]:
    targets containing `private` in their package path / name are implementation
    details and subject to change at any time (even if they have public visibility).
