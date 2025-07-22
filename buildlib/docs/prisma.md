<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Prisma rules.

Also see [examples/prisma/BUILD.bazel](../../examples/prisma/BUILD.bazel).


## Rules

- [prisma_dev](#prisma_dev)

## Macros

- [prisma_deploy_image](#prisma_deploy_image)
- [prisma_generate](#prisma_generate)
- [prisma_migrations](#prisma_migrations)
- [prisma_schema](#prisma_schema)


<a id="prisma_dev"></a>

## prisma_dev

<pre>
load("@dh_buildlib//prisma:defs.bzl", "prisma_dev")

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


<a id="prisma_deploy_image"></a>

## prisma_deploy_image

<pre>
load("@dh_buildlib//prisma:defs.bzl", "prisma_deploy_image")

prisma_deploy_image(*, <a href="#prisma_deploy_image-name">name</a>, <a href="#prisma_deploy_image-base">base</a>, <a href="#prisma_deploy_image-migrations">migrations</a>, <a href="#prisma_deploy_image-platform">platform</a>, <a href="#prisma_deploy_image-testonly">testonly</a>, <a href="#prisma_deploy_image-visibility">visibility</a>)
</pre>

Creates a docker image to run `prisma migrate deploy`

The image is intended to be used for upgrading database schemas in production environments.

Example: [`@examples//prisma:db-migrate`](../../examples/prisma/BUILD.bazel#:~:text=name%20%3D%20%22db%2Dmigrate%22%2C)

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="prisma_deploy_image-name"></a>name |  A unique name for this macro instance. Normally, this is also the name for the macro's main or only target. The names of any other targets that this macro might create will be this name with a string suffix.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="prisma_deploy_image-base"></a>base |  base image to use. defaults to: @node_image_linux_amd64   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `None`  |
| <a id="prisma_deploy_image-migrations"></a>migrations |  set of migrations to be included in the deploy image   | <a href="https://bazel.build/concepts/labels">Label</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | required |  |
| <a id="prisma_deploy_image-platform"></a>platform |  Platform of the base image.   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `"@dh_buildlib//private/docker:node_default_platform"`  |
| <a id="prisma_deploy_image-testonly"></a>testonly |  testonly flag   | Boolean; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `False`  |
| <a id="prisma_deploy_image-visibility"></a>visibility |  The visibility to be passed to this macro's exported targets. It always implicitly includes the location where this macro is instantiated, so this attribute only needs to be explicitly set if you want the macro's targets to be additionally visible somewhere else.   | <a href="https://bazel.build/concepts/labels">List of labels</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  |


<a id="prisma_generate"></a>

## prisma_generate

<pre>
load("@dh_buildlib//prisma:defs.bzl", "prisma_generate")

prisma_generate(*, <a href="#prisma_generate-name">name</a>, <a href="#prisma_generate-generators">generators</a>, <a href="#prisma_generate-schema">schema</a>, <a href="#prisma_generate-testonly">testonly</a>, <a href="#prisma_generate-visibility">visibility</a>)
</pre>

Rule to run prisma generation

To use this rule, you need to define at least one prisma generator and pass
it in the `generators` parameter.

See [prisma_generators.md](./prisma_generators.md) for available generators.

The generators defined in the Prisma schema need to be in sync with the
`generators` parameter. Each generator rule specifies how the `generator`
definition in the Prisma schema needs to look.

To link a generator to `prisma_generate`, you have to:
- Add a special target ending in `.generator` to `generators`
- Pass the prisma_generate target to the generator

```bzl
prisma_generate(
  name = "generate",
  generators = [":client.generator"],
  schema = "...",
)

prisma_client_js(
  name = "client",
  generate = ":generate",
)
```

Example: [`@examples//prisma:generate`](../../examples/prisma/BUILD.bazel#:~:text=name%20%3D%20%22generate%22%2C)

Also see [`@examples//prisma:schema.prisma`](../../examples/prisma/schema.prisma) for an example schema.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="prisma_generate-name"></a>name |  A unique name for this macro instance. Normally, this is also the name for the macro's main or only target. The names of any other targets that this macro might create will be this name with a string suffix.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="prisma_generate-generators"></a>generators |  The generators to link to   | <a href="https://bazel.build/concepts/labels">List of labels</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | required |  |
| <a id="prisma_generate-schema"></a>schema |  Prisma schema (must be in the same package)   | <a href="https://bazel.build/concepts/labels">Label</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | required |  |
| <a id="prisma_generate-testonly"></a>testonly |  Testonly flag   | Boolean; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `False`  |
| <a id="prisma_generate-visibility"></a>visibility |  The visibility to be passed to this macro's exported targets. It always implicitly includes the location where this macro is instantiated, so this attribute only needs to be explicitly set if you want the macro's targets to be additionally visible somewhere else.   | <a href="https://bazel.build/concepts/labels">List of labels</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  |


<a id="prisma_migrations"></a>

## prisma_migrations

<pre>
load("@dh_buildlib//prisma:defs.bzl", "prisma_migrations")

prisma_migrations(*, <a href="#prisma_migrations-name">name</a>, <a href="#prisma_migrations-srcs">srcs</a>, <a href="#prisma_migrations-schema">schema</a>, <a href="#prisma_migrations-tags">tags</a>, <a href="#prisma_migrations-testonly">testonly</a>, <a href="#prisma_migrations-validation_db_image">validation_db_image</a>, <a href="#prisma_migrations-visibility">visibility</a>)
</pre>

Declares and tests prisma migrations.

The test verifies the migrations are consistent with the schema.
In other words: if the test passes, running `prisma migrate dev` will not create a new migration.

Example: [`@examples//prisma:migrations`](../../examples/prisma/BUILD.bazel#:~:text=name%20%3D%20%22migrations%22%2C)

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="prisma_migrations-name"></a>name |  A unique name for this macro instance. Normally, this is also the name for the macro's main or only target. The names of any other targets that this macro might create will be this name with a string suffix.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="prisma_migrations-srcs"></a>srcs |  All files in the `migrations/` directory. Typically: `glob(["migrations/**"])`.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | required |  |
| <a id="prisma_migrations-schema"></a>schema |  The corresponding prisma_schema target.   | <a href="https://bazel.build/concepts/labels">Label</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | required |  |
| <a id="prisma_migrations-tags"></a>tags |  Tags   | List of strings; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `[]`  |
| <a id="prisma_migrations-testonly"></a>testonly |  Testonly flag   | Boolean; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `False`  |
| <a id="prisma_migrations-validation_db_image"></a>validation_db_image |  The database image to use to validate schema/migration consistency.   | <a href="https://bazel.build/concepts/labels">Label</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | required |  |
| <a id="prisma_migrations-visibility"></a>visibility |  The visibility to be passed to this macro's exported targets. It always implicitly includes the location where this macro is instantiated, so this attribute only needs to be explicitly set if you want the macro's targets to be additionally visible somewhere else.   | <a href="https://bazel.build/concepts/labels">List of labels</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  |


<a id="prisma_schema"></a>

## prisma_schema

<pre>
load("@dh_buildlib//prisma:defs.bzl", "prisma_schema")

prisma_schema(*, <a href="#prisma_schema-name">name</a>, <a href="#prisma_schema-db_url_env">db_url_env</a>, <a href="#prisma_schema-schema">schema</a>, <a href="#prisma_schema-testonly">testonly</a>, <a href="#prisma_schema-validate_db_url">validate_db_url</a>, <a href="#prisma_schema-visibility">visibility</a>)
</pre>

Declares a prisma schema, including a validation test.

Example: [`@examples//prisma:schema`](../../examples/prisma/BUILD.bazel#:~:text=name%20%3D%20%22schema%22%2C)

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="prisma_schema-name"></a>name |  A unique name for this macro instance. Normally, this is also the name for the macro's main or only target. The names of any other targets that this macro might create will be this name with a string suffix.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="prisma_schema-db_url_env"></a>db_url_env |  Environment variable name to use for the database URL.   | String | required |  |
| <a id="prisma_schema-schema"></a>schema |  schema file   | <a href="https://bazel.build/concepts/labels">Label</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | required |  |
| <a id="prisma_schema-testonly"></a>testonly |  Testonly flag   | Boolean; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `False`  |
| <a id="prisma_schema-validate_db_url"></a>validate_db_url |  Database URL to use when validating the schema. This URL only needs to be structurally valid (no db needs to run there).   | String | required |  |
| <a id="prisma_schema-visibility"></a>visibility |  The visibility to be passed to this macro's exported targets. It always implicitly includes the location where this macro is instantiated, so this attribute only needs to be explicitly set if you want the macro's targets to be additionally visible somewhere else.   | <a href="https://bazel.build/concepts/labels">List of labels</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  |


