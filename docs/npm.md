# Manage npm packages

## Add an npm dependency

The bazel setup uses pnpm (an npm alternative). To add / remove packages use the bazel provided pnpm like so:

```sh
bazelisk run -- //:pnpm <command>
```

For example, to install `my-npm-package`:

```sh
bazelisk run -- //:pnpm install my-npm-package
```

Further, please note:

- Installing a package is not enough to use it, you'll also need to add it as
  a dependency to the specific `ts_library` in the relevant `BUILD.bazel`.

## Install npm packages for IDEs

IDEs expect packages to be in the working copy under `node_modules`, but by
default, bazel does not put them there.

To install all packages, simply run:

```sh
bazelisk run -- //:pnpm install
```

This is **not** necessary to build or run the project.
