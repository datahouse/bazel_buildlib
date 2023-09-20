<!-- Generated with Stardoc: http://skydoc.bazel.build -->

GraphQL related rules.

<a id="gql_client_codegen"></a>

## gql_client_codegen

<pre>
gql_client_codegen(<a href="#gql_client_codegen-name">name</a>, <a href="#gql_client_codegen-gql_schema">gql_schema</a>, <a href="#gql_client_codegen-srcs">srcs</a>, <a href="#gql_client_codegen-testonly">testonly</a>)
</pre>

Generates a typed graphql client.

Example: [`@examples//frontend/src:gql`](../../examples/frontend/src/BUILD.bazel#:~:text=name%20%3D%20%22gql%22%2C)


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="gql_client_codegen-name"></a>name |  Name of the rule. The generated client will be available for import from a directory with the same name.   |  none |
| <a id="gql_client_codegen-gql_schema"></a>gql_schema |  GraphQL schema to work off of.   |  none |
| <a id="gql_client_codegen-srcs"></a>srcs |  Source files containing GraphQL queries.   |  `None` |
| <a id="gql_client_codegen-testonly"></a>testonly |  Testonly flag.   |  `None` |


<a id="gql_schema"></a>

## gql_schema

<pre>
gql_schema(<a href="#gql_schema-name">name</a>, <a href="#gql_schema-schema_import">schema_import</a>, <a href="#gql_schema-out">out</a>, <a href="#gql_schema-deps">deps</a>, <a href="#gql_schema-visibility">visibility</a>, <a href="#gql_schema-testonly">testonly</a>)
</pre>

Generate a .graphql file by importing TS code defining a schema.

Example: [`@examples//api:schema`](../../examples/api/BUILD.bazel#:~:text=name%20%3D%20%22schema%22%2C)


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="gql_schema-name"></a>name |  Name of the resulting rule.   |  none |
| <a id="gql_schema-schema_import"></a>schema_import |  Path to import the schema generation function from. - The function must be the default export of the module. - The function must be async and not take any parameters.   |  none |
| <a id="gql_schema-out"></a>out |  .graphql file to output to (typically schema.graqphl).   |  none |
| <a id="gql_schema-deps"></a>deps |  Typescript dependencies so the import works.   |  `[]` |
| <a id="gql_schema-visibility"></a>visibility |  Visibility of the schema.   |  `None` |
| <a id="gql_schema-testonly"></a>testonly |  Testonly flag.   |  `None` |


