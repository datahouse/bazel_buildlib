# Bzlmod Migration Instructions

Bzlmod is the new approach to managing Bazel dependencies (default in Bazel 7, released 2023-12).
The benefits of using bzlmod are listed
[in the official migration guide](https://bazel.build/external/migration#benefits-of-bzlmod).

At Datahouse, it makes management of Bazel dependencies significantly simpler
and as we move to Bazel 8, all projects should switch to bzlmod.

## Preparation

You will need to perform some housekeeping prior to migration, mostly relating
to ensuring dependency versions are sufficiently up to date.
These should not be done in the migration PR itself.

- Make sure you use new enough versions:

  - bazel >= 7.4.0 (check in `.bazelversion`)
  - dh_buildlib >= 14.1.0 (check in `WORKSPACE`)

- Remove any old npm install documentation.
  Link to the [authoritative documentation](https://git.datahouse.ch/datahouse/it-bazel/src/branch/main/docs/npm.md) instead.

  > [!IMPORTANT]
  >
  > `bazel run @pnpm` will stop working with bzlmod

- Remove hardcoded data / runfile paths to different bazel repositories.

  It is unlikely that you hit this (we have done some preliminary analysis on
  all git repos), but it is here for completeness.

  With bzlmod, the names of [repositories](https://bazel.build/concepts/build-ref#repositories)
  change. As a result, the paths to files in other repositories change
  (because they contain the repository name).

  It is best to remove reliance on the specific path mapping, and simply use
  [bazel's location expansion](https://bazel.build/reference/be/make-variables#predefined_label_variables)
  instead.

  Examples to get you started:

  - For a test: https://git.datahouse.ch/datahouse/it-bazel/pulls/886 (only the changes in `examples/`)
  - For a binary: https://git.datahouse.ch/datahouse/pl-projects/pulls/641
  - For a library: https://git.datahouse.ch/datahouse/pl-projects/pulls/642

## Migration PR

Example: https://git.datahouse.ch/datahouse/pl-projects/pulls/643

1. Create `project.bazelrc` containing

   ```
   common --enable_bzlmod
   ```

1. Create `MODULE.bazel` containing

   ```bzl
   bazel_dep(name = "dh_buildlib", version = "<version>")
   git_override(
       module_name = "dh_buildlib",
       commit = "<sha>",
       remote = "git@git.datahouse.ch:datahouse/it-bazel.git",
       strip_prefix = "buildlib",
   )
   ```

   Take `<version>` (without `v` prefix) and `<sha>` from `WORKSPACE`.

1. If you use Typescript, add this to `MODULE.bazel`

   ```diff
   +bazel_dep(name = "aspect_rules_js", version = "2.1.3")
   +bazel_dep(name = "aspect_rules_ts", version = "3.5.0")
   +
   bazel_dep(name = "dh_buildlib", version = "<version>")
   git_override(
       module_name = "dh_buildlib",
       commit = "<sha>",
       remote = "git@git.datahouse.ch:datahouse/it-bazel.git",
       strip_prefix = "buildlib",
   )
   +
   +npm = use_extension("@aspect_rules_js//npm:extensions.bzl", "npm")
   +use_repo(npm, "npm")
   +
   +rules_ts_ext = use_extension("@aspect_rules_ts//ts:extensions.bzl", "ext")
   +rules_ts_ext.deps(ts_version_from = "@npm//:typescript/resolved.json")
   +use_repo(rules_ts_ext, "npm_typescript")
   ```

1. If you use `oci_pull` in `WORKSPACE`, add this to `MODULE.bazel`

   ```diff
   +bazel_dep(name = "rules_oci", version = "2.2.2")
    bazel_dep(name = "dh_buildlib", version = "<version>")
    git_override(
        module_name = "dh_buildlib",
        commit = "<sha>",
        remote = "git@git.datahouse.ch:datahouse/it-bazel.git",
        strip_prefix = "buildlib",
    )
   +
   +oci = use_extension("@rules_oci//oci:extensions.bzl", "oci")
   +oci.pull(
   +    <things from oci_pull in WORKSPACE>
   +)
   +oci.pull(
   +    <add one oci.pull per oci_pull in WORKSPACE>
   +)
   ```

1. Empty `WORKSPACE` (https://git.datahouse.ch/datahouse/it-bazel/issues/1168)

1. Complete your `MODULE.bazel` file.

   1. Run `bazel mod tidy`
   1. Adjust the versions of dependencies according to warnings (if any).

      For example, if you get:

      ```
      WARNING: For repository 'rules_oci', the root module requires module version rules_oci@2.2.0, but got rules_oci@2.2.2 in the resolved dependency graph.
      ```

      Change:

      ```diff
      -bazel_dep(name = "rules_oci", version = "2.2.0")
      +bazel_dep(name = "rules_oci", version = "2.2.2")
      ```

   1. Run `bazel test //...`
   1. Add `bazel_dep` statements for other bazel libraries you use.

      For example, if you get:

      ```
      ERROR: error loading package under directory '': error loading package '': Unable to find package for @@[unknown repo 'aspect_bazel_lib' requested from @@]//lib:tar.bzl: The repository '@@[unknown repo 'aspect_bazel_lib' requested from @@]' could not be resolved: No repository visible as '@aspect_bazel_lib' from main repository.
      ```

      Add the following to the top of MODULE.bazel

      ```diff
      +bazel_dep(name = "aspect_bazel_lib", version = "2.13.0")
      ```

      See [`examples/MODULE.bazel`](../examples/MODULE.bazel) for common libraries.

   1. Repeat until tests pass and there are no more warnings.

1. Commit
   - Add `project.bazelrc`
   - Add `MODULE.bazel`
   - Add `MODULE.bazel.lock`
   - Modified `WORKSPACE`
