import { gql } from "./gql/index.js";

// GQL queries that need to be in a separate module to avoid circular imports.

export const GET_ACTIVE_TODOS = gql(`
  query getActiveTodos {
    todoLists(where: { archived: { equals: false } }, orderBy: { name: asc }) {
      id
      ...TodoListFields
    }
  }
`);

export const GET_ATTACHMENTS = gql(`
  query getAttachments ($itemId: Int!) {
    todoAttachments(where: { itemId: { equals: $itemId } }, orderBy: { filename: asc }) {
      id
      filename
      uuid
    }
  }
`);
