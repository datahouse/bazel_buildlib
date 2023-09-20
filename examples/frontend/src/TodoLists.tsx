import React from "react";

import { useQuery } from "@apollo/client";
import { gql } from "./gql";

// exported for testing
export const GET_ACTIVE_TODO_LISTS = gql(`
  query getActiveTodoLists {
    todoLists(where: { archived: { equals: false } }, orderBy: { name: asc }) {
      id
      name
    }
  }
`);

export default function TodoLists() {
  const { loading, error, data } = useQuery(GET_ACTIVE_TODO_LISTS);

  if (error) return <p>Error: {error.message}</p>;
  if (loading || data === undefined) return <p>Loading your todo lists...</p>;

  return (
    <ul>
      {data.todoLists.map(({ id, name }) => (
        <li key={id}>{name}</li>
      ))}
    </ul>
  );
}
