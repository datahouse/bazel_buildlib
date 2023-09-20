# Datahouse Example Project

This project shows various examples. At the same time, it serves as integration test for the `dh_buildlib`.

`shared-lib`
: A shared TS library that could be used by multiple backend containers or even the frontend.

`shared-fe-lib`
: A shared frontend TS library.

`proxy`
: Proxy container (main application entrypoint)

`frontend`
: React frontend application.

`api`
: GraphQL API using typegraphql-prisma. See `api/README.md` for example queries.

`prisma`
: Prisma setup including typegraphql-prisma client generation.

`rest-api`
: Example REST API with tsoa.

`scripts`
: Example integration / glue scripts (a typical project doesn't need these).

## Start the docker composition

```sh
bazelisk run //dc -- up
```

## Reset the DB

Note:

- This is not done automatically
- The db container needs to be running for this
- This will delete all existing data and setup a clean DB with testing data

```sh
bazelisk run //prisma -- migrate reset
```

## Automatic reload

For all commands, `bazelisk` can be replaced with `ibazel` to automatically reload. For example:

```sh
ibazel run //dc -- up -d
```

Note the `-d` flag: The containers will keep running in the background even if
the command is terminated. However, this allows to recreate only changed containers.

## Build & Test

For example, to build / test everything:

```sh
bazelisk build //...
bazelisk test //...
```
