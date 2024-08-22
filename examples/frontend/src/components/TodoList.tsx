import { useState } from "react";

import { List, ListItem, ListItemButton, styled } from "@mui/joy";

import { KeyboardArrowDown, KeyboardArrowRight } from "@mui/icons-material";

import { FragmentType, gql, useFragment } from "../gql/index.js";

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
  list: FragmentType<typeof TODO_LIST_FIELDS_FRAGMENT>;
  initiallyExpanded: boolean;
}

export default function TodoList({ list, initiallyExpanded }: Props) {
  const { name, items } = useFragment(TODO_LIST_FIELDS_FRAGMENT, list);

  const [isExpanded, setIsExpanded] = useState(initiallyExpanded);

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
