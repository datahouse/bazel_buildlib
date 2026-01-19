<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Prisma generator rules.

For information about how to use prisma generator rules, please consult
the documentation of [`prisma_generate`](./prisma.md#prisma_generate)


## Macros

- [prisma_client](#prisma_client)
- [prisma_client_js](#prisma_client_js)
- [typegraphql_prisma](#typegraphql_prisma)


<a id="prisma_client"></a>

## prisma_client

<pre>
load("@dh_buildlib//prisma/generators:defs.bzl", "prisma_client")

prisma_client(*, <a href="#prisma_client-name">name</a>, <a href="#prisma_client-generate">generate</a>, <a href="#prisma_client-testonly">testonly</a>, <a href="#prisma_client-visibility">visibility</a>)
</pre>

Defines a prisma generator with the prisma-client provider.

Requires:
- prisma >= 6.16.0.
- typescript (enable_ts in buildlib_setup)

For a generator with name `<name>`, you need (at least) the following settings in the the Prisma Schema:

```
generator <anything> {
  provider            = "prisma-client"
  output              = "<name>"
  moduleFormat        = "cjs"
  importFileExtension = "js"
}
```

Example: [`@prisma-musl-no-typegraphql//prisma:client`](../../tests/prisma-musl-no-typegraphql/prisma/BUILD.bazel#:~:text=name%20%3D%20%22client%22%2C)

For more: https://www.prisma.io/docs/orm/prisma-schema/overview/generators

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="prisma_client-name"></a>name |  A unique name for this macro instance. Normally, this is also the name for the macro's main or only target. The names of any other targets that this macro might create will be this name with a string suffix.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="prisma_client-generate"></a>generate |  The prisma_generate target containing this generator   | <a href="https://bazel.build/concepts/labels">Label</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | required |  |
| <a id="prisma_client-testonly"></a>testonly |  Testonly flag   | Boolean; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `False`  |
| <a id="prisma_client-visibility"></a>visibility |  The visibility to be passed to this macro's exported targets. It always implicitly includes the location where this macro is instantiated, so this attribute only needs to be explicitly set if you want the macro's targets to be additionally visible somewhere else.   | <a href="https://bazel.build/concepts/labels">List of labels</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  |


<a id="prisma_client_js"></a>

## prisma_client_js

<pre>
load("@dh_buildlib//prisma/generators:defs.bzl", "prisma_client_js")

prisma_client_js(*, <a href="#prisma_client_js-name">name</a>, <a href="#prisma_client_js-generate">generate</a>, <a href="#prisma_client_js-testonly">testonly</a>, <a href="#prisma_client_js-visibility">visibility</a>)
</pre>

Defines a prisma generator with the prisma-client-js provider.

For a generator with name `<name>`, you need (at least) the following settings in the the Prisma Schema:

```
generator <anything> {
  provider      = "prisma-client-js"
  output        = "<name>"
}
```

Example: [`@examples//prisma:prisma-client`](../../examples/prisma/BUILD.bazel#:~:text=name%20%3D%20%22prisma%2Dclient%22%2C)

For more: https://www.prisma.io/docs/concepts/components/prisma-client/working-with-prismaclient/generating-prisma-client

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="prisma_client_js-name"></a>name |  A unique name for this macro instance. Normally, this is also the name for the macro's main or only target. The names of any other targets that this macro might create will be this name with a string suffix.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="prisma_client_js-generate"></a>generate |  The prisma_generate target containing this generator   | <a href="https://bazel.build/concepts/labels">Label</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | required |  |
| <a id="prisma_client_js-testonly"></a>testonly |  Testonly flag   | Boolean; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `False`  |
| <a id="prisma_client_js-visibility"></a>visibility |  The visibility to be passed to this macro's exported targets. It always implicitly includes the location where this macro is instantiated, so this attribute only needs to be explicitly set if you want the macro's targets to be additionally visible somewhere else.   | <a href="https://bazel.build/concepts/labels">List of labels</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  |


<a id="typegraphql_prisma"></a>

## typegraphql_prisma

<pre>
load("@dh_buildlib//prisma/generators:defs.bzl", "typegraphql_prisma")

typegraphql_prisma(*, <a href="#typegraphql_prisma-name">name</a>, <a href="#typegraphql_prisma-generate">generate</a>, <a href="#typegraphql_prisma-prisma_client">prisma_client</a>, <a href="#typegraphql_prisma-testonly">testonly</a>, <a href="#typegraphql_prisma-visibility">visibility</a>)
</pre>

Defines a prisma generator with the typegraphql-prisma provider.

For a generator with name `<name>`, you need (at least) the following settings in the the Prisma schema:

```
generator <anything> {
  provider           = "typegraphql-prisma"
  output             = "<name>"
  emitTranspiledCode = true
}
```

Example: [`@examples//prisma:typegraphql-prisma`](../../examples/prisma/BUILD.bazel#:~:text=name%20%3D%20%22typegraphql%2Dprisma%22%2C)

For more: https://prisma.typegraphql.com/docs/basics/configuration

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="typegraphql_prisma-name"></a>name |  A unique name for this macro instance. Normally, this is also the name for the macro's main or only target. The names of any other targets that this macro might create will be this name with a string suffix.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="typegraphql_prisma-generate"></a>generate |  The prisma_generate target containing this generator   | <a href="https://bazel.build/concepts/labels">Label</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | required |  |
| <a id="typegraphql_prisma-prisma_client"></a>prisma_client |  The prisma client to use in the generated resolvers   | <a href="https://bazel.build/concepts/labels">Label</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | required |  |
| <a id="typegraphql_prisma-testonly"></a>testonly |  Testonly flag   | Boolean; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `False`  |
| <a id="typegraphql_prisma-visibility"></a>visibility |  The visibility to be passed to this macro's exported targets. It always implicitly includes the location where this macro is instantiated, so this attribute only needs to be explicitly set if you want the macro's targets to be additionally visible somewhere else.   | <a href="https://bazel.build/concepts/labels">List of labels</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  |


