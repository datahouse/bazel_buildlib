import { useState } from "react";

import { List, ListItem, ListItemButton, styled } from "@mui/joy";

import KeyboardArrowDown from "@mui/icons-material/KeyboardArrowDown";
import KeyboardArrowRight from "@mui/icons-material/KeyboardArrowRight";

import { FragmentType, gql, useFragment } from "../gql/index.js";

import TodoItem from "./TodoItem.js";

const TODO_LIST_FIELDS_FRAGMENT = gql(`
  fragment TodoListFields on TodoList {
    name
    items {
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
}

export default function TodoList({ list }: Props) {
  const { name, items } = useFragment(TODO_LIST_FIELDS_FRAGMENT, list);

  const [open, setOpen] = useState(false);

  const itemsSubList = (
    <NestedList>
      {items.map((item) => (
        <TodoItem key={item.id} item={item} />
      ))}
    </NestedList>
  );

  return (
    <ListItem nested>
      <ListItemButton onClick={() => setOpen(!open)}>
        {open ? <KeyboardArrowDown /> : <KeyboardArrowRight />}
        {name}
      </ListItemButton>

      {open && itemsSubList}
    </ListItem>
  );
}
