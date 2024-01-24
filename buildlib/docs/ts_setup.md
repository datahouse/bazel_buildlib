<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Rules to set up the JavaScript / Typescript base system.

For a typical project, it is best to just use [`ts_setup`](#ts_setup) which
instantiates all the other rules.

However, the individual rules are also provided, in case more fine grained
control is needed.

<a id="eslintrc"></a>

## eslintrc

<pre>
eslintrc(<a href="#eslintrc-name">name</a>, <a href="#eslintrc-visibility">visibility</a>)
</pre>

Declares an eslintrc file.

The following source files are implicititly depended on:
- .eslintrc.js (main config)
- .eslintignore (if it exists)
- package.json
- tsconfig-base.json

Provides a test that ensures the eslintrc includes the Datahouse base eslint
config.

Example: See [`ts_setup`](#ts_setup)


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="eslintrc-name"></a>name |  Name of the rule. Must be "eslintrc".   |  none |
| <a id="eslintrc-visibility"></a>visibility |  Visibility of the eslintrc rule.   |  `None` |


<a id="pnpm_lock_test"></a>

## pnpm_lock_test

<pre>
pnpm_lock_test(<a href="#pnpm_lock_test-name">name</a>)
</pre>

Tests that package.json and pnpm-lock.yaml are in sync.

Both of these files are implicitly depended upon.

Examples:
- See [`ts_setup`](#ts_setup)
- [`@buildlib//private:pnpm_lock_test`](../private/BUILD.bazel#:~:text=name%20%3D%20%22pnpm_lock_test%22%2C)


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="pnpm_lock_test-name"></a>name |  Name of the test (suggested: `pnpm_lock_test`).   |  none |


<a id="ts_setup"></a>

## ts_setup

<pre>
ts_setup(<a href="#ts_setup-name">name</a>)
</pre>

Utility macro to reduce boilerplate for JavaScript / Typescript setup.

Example: [`@examples//:ts_setup`](../../examples/BUILD.bazel#:~:text=name%20%3D%20%22ts_setup%22%2C)

Strictly equivalent to (but this may evolve over time):

```
tsconfig_base(
    name = "tsconfig-base",
    visibility = ["//:__subpackages__"],
)

eslintrc(
    name = "eslintrc",
    visibility = ["//:__subpackages__"],
)

pnpm_lock_test(
    name = "pnpm_lock_test",
)
```


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="ts_setup-name"></a>name |  Dummy name argument (for tool support / rule shape). Must be `ts_setup`.   |  none |


<a id="tsconfig_base"></a>

## tsconfig_base

<pre>
tsconfig_base(<a href="#tsconfig_base-name">name</a>, <a href="#tsconfig_base-visibility">visibility</a>)
</pre>

Base tsconfig for repository root.

- must be in the root package
- name must be tsconfig-base

Example: See [`ts_setup`](#ts_setup)


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="tsconfig_base-name"></a>name |  Name of the rule (must be "tsconfig-base").   |  none |
| <a id="tsconfig_base-visibility"></a>visibility |  Visibility of the tsconfig rule.   |  `None` |


