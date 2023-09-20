# GraphQL API server

Example queries (paste them in the query explorer at `http://api-it-bazel-examples.localhost/`):

```
query MyActiveLists {
  todoLists(where: {archived: { equals: false }}, orderBy: { name: desc }) {
    name,
    items {
      done
      text
    }
  }
}

query AllMyTODOs {
  todoItems(where: {done: { equals: false} }, orderBy: { text: desc }) {
    text,
    list { name },
  }
}
```
