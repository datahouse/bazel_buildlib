# Datahouse Bazel Build Library

Quick dump of what we have internally so folks in the bazel community can look at it.

- Highly opinionated (!). Do not expect that you can use anything in here as-is, but it can serve as a staring point / example.
- Only tested internally. I might make mistakes when exporting or forget files.
- Will lag behind.

[API Docs](./buildlib/docs/README.md).

# Internal Setup doc

Here because there is no point in deleting it, but likely not relevant to the target audience of this repo.

## Bazel Setup

```sh
npm install -g @bazel/bazelisk
npm install -g @bazel/ibazel
sudo apt-get install docker-compose-plugin
```

## Setup a new repository

1. Setup bazel (see above).
1. Copy the following from `examples/` to the root of the new repository:

   - `WORKSPACE`
   - `BUILD.bazel`
   - `.bazelversion`
   - `.bazelignore`
   - `.npmrc`
   - `.nvmrc`
   - `.eslintrc.js`
   - `.gitignore`

1. Address and remove the comments in the following files:

   - `WORKSPACE`
   - `BUILD.bazel`
   - `.eslintrc.js`

1. Bootstrap pnpm:

   ```sh
   touch pnpm-lock.yaml
   bazelisk run -- @pnpm//:pnpm --dir $PWD install --save-dev --save-exact typescript
   ```

1. Run `bazelisk build //...` and address the problems until it doesn't fail anymore.

   You'll need to create / update automatically generated files:
   Some messages will tell you to `bazel run ...`. Do `bazelisk run ...` instead.

1. Run `bazelisk test //...` and check it passes.

1. Base setup complete (probably a good point to commit and push).

1. Proceed to set-up the parts of the example you need for your project.

## Add an npm dependency

The bazel setup uses pnpm (an npm alternative). To add / remove packages use the bazel provided pnpm like so:

```sh
bazelisk run -- @pnpm//:pnpm --dir $PWD <command>
```

For example, to install `my-npm-package`:

```sh
bazelisk run -- @pnpm//:pnpm --dir $PWD install --save-exact my-npm-package
```

Further, please note:

- Make sure you use exact versions (use `npm --save-exact`)
- Installing a package is not enough to use it, you'll also need to add it as
  a dependency to the specific `ts_library` in the relevant `BUILD.bazel`.

## Install npm packages for IDEs

IDEs expect packages to be in the working copy under `node_modules`, but by
default, bazel does not put them there.

To install all packages, simply run:

```sh
bazelisk run -- @pnpm//:pnpm --dir $PWD install
```

This is **not** necessary to build or run the project.
