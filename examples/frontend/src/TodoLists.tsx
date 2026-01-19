import { List, ListSubheader, Sheet, styled } from "@mui/joy";

import { useSuspenseQuery } from "@apollo/client/react";

import { GET_ACTIVE_TODOS } from "./queries.js";

import TodoList from "./components/TodoList.js";
import LoadBoundary from "./components/LoadBoundary.js";

const Container = styled("div")`
  max-width: 50em;
  margin: 1em auto;
`;

// Inner component so that the call to useSuspenseQuery is inside the LoadBoundary.
function TodoListsList() {
  const { data } = useSuspenseQuery(GET_ACTIVE_TODOS);

  return (
    <List size="lg">
      <ListSubheader>Your TODO lists</ListSubheader>
      {data.todoLists.map((list, index) => (
        <TodoList key={list.id} list={list} initiallyExpanded={index === 0} />
      ))}
    </List>
  );
}

export default function TodoLists() {
  return (
    <Container>
      <LoadBoundary itemDesc="your TODOs">
        <Sheet variant="outlined">
          <TodoListsList />
        </Sheet>
      </LoadBoundary>
    </Container>
  );
}
