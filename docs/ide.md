# IDE tips

## Disclaimer

This document is community maintained! If you have additional tips for an existing IDE or for a new IDE, file a PR.

## VSCode

### VSCode does not find `node_modules`

see [NPM docs](./npm.md#install-npm-packages-for-ides)

### Frontend

#### GraphQL Query Autocomplete and Schema Validation

When you write queries/mutations in your frontend, it is useful when the IDE understands what the GraphQL schema contains to allow autocomplete (what fields are available) and validation.
For that you install the [offical GraphQL extension](https://marketplace.visualstudio.com/items?itemName=GraphQL.vscode-graphql).

For the Extension to work, it has to know where your schema exists. In the project root directory you need to add a config file named: `graphql.config.yml`.

```yaml
schema: "./bazel-bin/api/schema.graphql"
documents: "./frontend/src/**/*.{tsx,ts}"
```

Make sure that this does not end up in the repo (never commit or stage this file to git).
To prevent accidential commits you can add `graphql.config.yml` to your **global** gitignore, see this instruction on [how to setup global gitignore](https://sebastiandedeyne.com/setting-up-a-global-gitignore-file/).

[Also see #291](https://git.datahouse.ch/datahouse/it-bazel/issues/291)

##### When I change the schema (add/remove fields) my IDE still validates with the previous version

This is because the schema does not get build with the target configuration (so the latest schema does not exist in `bazel-bin`) but only in a transition configuration.
Either you manualy rebuild the schema with `bazelisk build //api:schema` (or even with `ibazel` for automatic reload but be aware that this blocks your docker container from instantly rebuilding because only one ibazel command can compute and build stuff at the same time).

Or you change to the transition configuration that is valid for your current project and platform:
e.g. `schema: "./bazel-out/k8-fastbuild-ST-e2fe75a64bc0/bin/api/schema.graphql`.
Be aware that the hash might be a different one for your platform so if you want to use this approach you have to manualy find the correct transition configuration in `bazel-out` (the one that has the `schema.graphql` under `/bin/api/`).

[Also see #698](https://git.datahouse.ch/datahouse/it-bazel/issues/698)

#### Frontend Types do not exist after writing new query/mutation

This is a similar problem as stated above so you can just manualy rebuild the types:
`bazelisk build //frontend/src:gql` or with `ibazel`.

#### After manually rebuilding my VSCode still does not recognize the new types

Try to reload the window with the VSCode command `>Developer: Reload Window` this forces the language servers to reindex the content of the project and will then recognize the new types.
