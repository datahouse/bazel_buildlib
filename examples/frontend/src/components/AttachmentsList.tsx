import { List, ListItem, IconButton, ListItemButton } from "@mui/joy";

import { Delete } from "@mui/icons-material";

import { useSuspenseQuery } from "@apollo/client";

import { GET_ATTACHMENTS } from "../queries.js";

interface AttachmentItemProps {
  uuid: string;
  filename: string;
}

function AttachmentItem({ uuid, filename }: AttachmentItemProps) {
  const deleteButton = (
    <IconButton aria-label="Delete" size="sm" color="danger">
      <Delete />
    </IconButton>
  );

  return (
    <ListItem endAction={deleteButton}>
      <ListItemButton
        component="a"
        rel="noopener noreferrer"
        href={`/blob/todoAttachment/${uuid}`}
        target="_blank"
      >
        {filename}
      </ListItemButton>
    </ListItem>
  );
}

export interface Props {
  itemId: number;
}

export default function AttachmentsList({ itemId }: Props) {
  const { data } = useSuspenseQuery(GET_ATTACHMENTS, {
    variables: { itemId },
  });

  return (
    <List>
      {data.todoAttachments.map(({ id, uuid, filename }) => (
        <AttachmentItem key={id} uuid={uuid} filename={filename} />
      ))}
    </List>
  );
}
