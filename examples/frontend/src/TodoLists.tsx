import { Alert, List, ListSubheader, Sheet, styled } from "@mui/joy";

import { useQuery } from "@apollo/client";

import { GET_ACTIVE_TODOS } from "./queries.js";

import TodoList from "./components/TodoList.js";

const Container = styled("div")`
  max-width: 50em;
  margin: 1em auto;
`;

export default function TodoLists() {
  const { loading, error, data } = useQuery(GET_ACTIVE_TODOS);

  // IIFE for "local" early return.
  const content = (() => {
    if (error) {
      return (
        <Alert color="danger" variant="soft">
          Error: {error.message}
        </Alert>
      );
    }

    if (loading || data === undefined) {
      return (
        <Alert color="warning" variant="soft">
          Loading your TODOs...
        </Alert>
      );
    }

    return (
      <Sheet variant="outlined">
        <List size="lg">
          <ListSubheader>Your TODO lists</ListSubheader>
          {data.todoLists.map((list) => (
            <TodoList key={list.id} list={list} />
          ))}
        </List>
      </Sheet>
    );
  })();

  return <Container>{content}</Container>;
}
