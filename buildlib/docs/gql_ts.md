<!-- Generated with Stardoc: http://skydoc.bazel.build -->

GraphQL related rules.


## Functions

- [gql_schema](#gql_schema)


<a id="gql_schema"></a>

## gql_schema

<pre>
load("@dh_buildlib//gql/ts:defs.bzl", "gql_schema")

gql_schema(<a href="#gql_schema-name">name</a>, <a href="#gql_schema-schema_import">schema_import</a>, <a href="#gql_schema-out">out</a>, <a href="#gql_schema-deps">deps</a>, <a href="#gql_schema-visibility">visibility</a>, <a href="#gql_schema-testonly">testonly</a>)
</pre>

Generate a .graphql file by importing TS code defining a schema.

Example: [`@examples//api:schema`](../../examples/api/BUILD.bazel#:~:text=name%20%3D%20%22schema%22%2C)


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="gql_schema-name"></a>name |  Name of the resulting rule.   |  none |
| <a id="gql_schema-schema_import"></a>schema_import |  Path to import the schema generation function from. - The function must be the default export of the module. - The function must be async and not take any parameters. - The path must have a `.js` extension (to ensure ESM compatibility).   |  none |
| <a id="gql_schema-out"></a>out |  .graphql file to output to (typically schema.graqphl).   |  none |
| <a id="gql_schema-deps"></a>deps |  Typescript dependencies so the import works.   |  `[]` |
| <a id="gql_schema-visibility"></a>visibility |  Visibility of the schema.   |  `None` |
| <a id="gql_schema-testonly"></a>testonly |  Testonly flag.   |  `None` |


