import { useState } from "react";

import { List, ListItem, ListItemButton, styled } from "@mui/joy";

import { KeyboardArrowDown, KeyboardArrowRight } from "@mui/icons-material";

import { FragmentType, useSuspenseFragment } from "@apollo/client";

import { gql } from "../../gql/index.js";
import { TodoListFieldsFragment } from "../../gql/graphql.js";

import TodoItem from "./TodoItem.js";

const TODO_LIST_FIELDS_FRAGMENT = gql(`
  fragment TodoListFields on TodoList {
    name
    items(orderBy: [{ done: asc }, { text: asc }]) {
      id
      ...TodoItemFields
    }
  }
`);

const NestedList = styled(List)`
  --ListItem-paddingLeft: 21px;
`;

export interface Props {
  list: FragmentType<TodoListFieldsFragment>;
  initiallyExpanded?: boolean;
}

export default function TodoList({ list, initiallyExpanded = false }: Props) {
  const [isExpanded, setIsExpanded] = useState(initiallyExpanded);

  const {
    data: { items, name },
  } = useSuspenseFragment({
    fragment: TODO_LIST_FIELDS_FRAGMENT,
    fragmentName: "TodoListFields",
    from: list,
  });

  const itemsSubList = (
    <NestedList>
      {items.map((item) => (
        <TodoItem key={item.id} item={item} />
      ))}
    </NestedList>
  );

  return (
    <ListItem nested>
      <ListItemButton onClick={() => setIsExpanded(!isExpanded)}>
        {isExpanded ? <KeyboardArrowDown /> : <KeyboardArrowRight />}
        {name}
      </ListItemButton>

      {isExpanded && itemsSubList}
    </ListItem>
  );
}
