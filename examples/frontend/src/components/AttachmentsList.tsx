import { List, ListItem, IconButton, ListItemButton } from "@mui/joy";

import { Delete } from "@mui/icons-material";

import { useSuspenseQuery } from "@apollo/client/react";

import { GET_ATTACHMENTS } from "../queries.js";

interface AttachmentItemProps {
  uuid: string;
  filename: string;
  onDelete: () => void;
}

function AttachmentItem({ uuid, filename, onDelete }: AttachmentItemProps) {
  const deleteButton = (
    <IconButton
      aria-label={`Delete ${filename}`}
      size="sm"
      color="danger"
      onClick={onDelete}
    >
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
  deleteAttachment: (attachmentId: number) => void;
}

export default function AttachmentsList({ itemId, deleteAttachment }: Props) {
  const { data } = useSuspenseQuery(GET_ATTACHMENTS, {
    variables: { itemId },
  });

  return (
    <List>
      {data.todoAttachments.map(({ id, uuid, filename }) => (
        <AttachmentItem
          key={id}
          uuid={uuid}
          filename={filename}
          onDelete={() => deleteAttachment(id)}
        />
      ))}
    </List>
  );
}
