<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Prisma rules.

Also see [examples/prisma/BUILD.bazel](../../examples/prisma/BUILD.bazel).

<a id="prisma_dev"></a>

## prisma_dev

<pre>
prisma_dev(<a href="#prisma_dev-name">name</a>, <a href="#prisma_dev-db_service">db_service</a>, <a href="#prisma_dev-db_url">db_url</a>, <a href="#prisma_dev-schema">schema</a>, <a href="#prisma_dev-seed_script">seed_script</a>)
</pre>

Run the prisma CLI against a docker compose managed database.

Example: [`@examples//prisma`](../../examples/prisma/BUILD.bazel#:~:text=name%20%3D%20%22prisma%22%2C)

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="prisma_dev-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="prisma_dev-db_service"></a>db_service |  dc_service_reference of the database to connect to.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="prisma_dev-db_url"></a>db_url |  Database URL template to connect to.<br><br>The env variable DB_SERVICE is available for substitution and will be set with the location of the discovered db_service (`host:port`).   | String | required |  |
| <a id="prisma_dev-schema"></a>schema |  Schema to run with.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="prisma_dev-seed_script"></a>seed_script |  Executable passed as seed script to prisma (optional).   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `None`  |


<a id="prisma_cli_image"></a>

## prisma_cli_image

<pre>
prisma_cli_image(<a href="#prisma_cli_image-name">name</a>, <a href="#prisma_cli_image-schema">schema</a>, <a href="#prisma_cli_image-base">base</a>, <a href="#prisma_cli_image-platform">platform</a>, <a href="#prisma_cli_image-visibility">visibility</a>, <a href="#prisma_cli_image-testonly">testonly</a>)
</pre>

Generates a docker image for executing the prisma cli.

Example: [`@examples//prisma:cli`](../../examples/prisma/BUILD.bazel#:~:text=name%20%3D%20%22cli%22%2C)


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="prisma_cli_image-name"></a>name |  name of the rule.   |  none |
| <a id="prisma_cli_image-schema"></a>schema |  prisma schema to use.   |  none |
| <a id="prisma_cli_image-base"></a>base |  base image to use   |  `"@node_image//image"` |
| <a id="prisma_cli_image-platform"></a>platform |  Platform of the base image.   |  `Label("//private/docker:node_default_platform")` |
| <a id="prisma_cli_image-visibility"></a>visibility |  visibility of the rule   |  `None` |
| <a id="prisma_cli_image-testonly"></a>testonly |  testonly flag for all targets.   |  `None` |


<a id="prisma_generate"></a>

## prisma_generate

<pre>
prisma_generate(<a href="#prisma_generate-name">name</a>, <a href="#prisma_generate-schema">schema</a>, <a href="#prisma_generate-generators">generators</a>, <a href="#prisma_generate-visibility">visibility</a>, <a href="#prisma_generate-testonly">testonly</a>)
</pre>

Rule to set-up prisma client generation.

The generators in the Prisma schema need to be in sync with the `generators` parameter:
A dictionary from generated target names to the definition of the relevant provider
(on the `prisma_providers` struct).

A typical `generators` value for typegraphql-prisma would be:

```
generators = {
    "prisma-client": prisma_providers.prisma_client_js(),
    "typegraphql-prisma": prisma_providers.typegraphql_prisma(
        prisma_client = ":prisma-client"
    ),
}
```

For now, this is the default, but the generators parameter will become mandatory in the future.

Example: [`@examples//prisma:generate`](../../examples/prisma/BUILD.bazel#:~:text=name%20%3D%20%22generate%22%2C)

Also see [`@examples//prisma:schema.prisma`](../../examples/prisma/schema.prisma) for an example schema.


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="prisma_generate-name"></a>name |  name of the rule.   |  none |
| <a id="prisma_generate-schema"></a>schema |  Prisma schema file (must be in the package directory).   |  none |
| <a id="prisma_generate-generators"></a>generators |  Dictionary from generated target name to Prisma provider. The values in this dictionary must be obtained by calling one of the functions in prisma_providers.   |  `None` |
| <a id="prisma_generate-visibility"></a>visibility |  visibility of the generated targets.   |  `None` |
| <a id="prisma_generate-testonly"></a>testonly |  testonly flag for all targets.   |  `None` |


<a id="prisma_providers.prisma_client_js"></a>

## prisma_providers.prisma_client_js

<pre>
prisma_providers.prisma_client_js()
</pre>

The default Prisma Client provider.

For a generator with name `<name>`, you need (at least) the following settings in the the Prisma Schema:

```
generator <anything> {
  provider      = "prisma-client-js"
  output        = "<name>"
  binaryTargets = env("BINARY_TARGET")
}
```

For more:
https://www.prisma.io/docs/concepts/components/prisma-client/working-with-prismaclient/generating-prisma-client



<a id="prisma_providers.typegraphql_prisma"></a>

## prisma_providers.typegraphql_prisma

<pre>
prisma_providers.typegraphql_prisma(<a href="#prisma_providers.typegraphql_prisma-prisma_client">prisma_client</a>)
</pre>

Typegraphql Prisma provider.

For a generator with name `<name>`, you need (at least) the following settings in the the Prisma Schema:

```
generator <anything> {
  provider           = "typegraphql-prisma"
  output             = "<name>"
  emitTranspiledCode = true
}
```

For more: https://prisma.typegraphql.com/docs/basics/configuration


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="prisma_providers.typegraphql_prisma-prisma_client"></a>prisma_client |  Label (name) of the / a generator with prisma_client_js provider.   |  none |


<a id="prisma_schema"></a>

## prisma_schema

<pre>
prisma_schema(<a href="#prisma_schema-name">name</a>, <a href="#prisma_schema-schema">schema</a>, <a href="#prisma_schema-db_url_env">db_url_env</a>, <a href="#prisma_schema-validate_db_url">validate_db_url</a>, <a href="#prisma_schema-visibility">visibility</a>, <a href="#prisma_schema-testonly">testonly</a>)
</pre>

Declares a prisma schema, including a validation test.

Example: [`@examples//prisma:schema`](../../examples/prisma/BUILD.bazel#:~:text=name%20%3D%20%22schema%22%2C)


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="prisma_schema-name"></a>name |  name of the rule   |  none |
| <a id="prisma_schema-schema"></a>schema |  schema file   |  none |
| <a id="prisma_schema-db_url_env"></a>db_url_env |  Environment variable name to use for the database URL.   |  none |
| <a id="prisma_schema-validate_db_url"></a>validate_db_url |  Database URL to use when validating the schema. This URL only needs to be structurally valid (no db needs to run there).   |  none |
| <a id="prisma_schema-visibility"></a>visibility |  visibility of main schema rule.   |  `None` |
| <a id="prisma_schema-testonly"></a>testonly |  testonly flag   |  `None` |


