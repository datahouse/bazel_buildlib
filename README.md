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
1. Run `./new-repo.sh DIRECTORY`. This will create and set up a git repo.

1. Optional: Set up the repo on git.datahouse.ch

   1. Create a new repo (make sure the project is in the
      [project list](https://git.datahouse.ch/datahouse/pl-projects/src/branch/master/projects.md)).
   1. Log into https://drone.datahouse.ch
   1. On the Dashboard, click "Sync"
   1. Search for the repository (make sure you display inactive repositories) and click on it.
   1. Click "Activate Repository".
   1. Push the local git repository to it:

      ```sh
      git remote add origin git@git.datahouse.ch:datahouse/project-<TLA>.git`
      git push --set-upstream origin main
      ```

   1. Check that the Drone build triggered (and succeeded).

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
