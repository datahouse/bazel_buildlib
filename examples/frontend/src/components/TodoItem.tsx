import {
  ListItem,
  Checkbox,
  IconButton,
  Snackbar,
  Badge,
  styled,
} from "@mui/joy";

import type { FormEvent } from "react";

import CloudUploadIcon from "@mui/icons-material/CloudUpload";

import { useMutation } from "@apollo/client";

import { FragmentType, gql, useFragment } from "../gql/index.js";

import { GET_ACTIVE_TODOS } from "../queries.js";

const TODO_ITEM_FIELDS_FRAGMENT = gql(`
  fragment TodoItemFields on TodoItem {
    id
    text
    done
    _count { attachments }
  }
`);

// exported for testing
export const UPLOAD_TODO_ATTACHMENT = gql(`
  mutation uploadTodoAttachment ($file: Upload!, $itemId: Int!) {
    uploadTodoAttachment (
      file: $file
      itemId: $itemId
    )
  }
`);

export interface Props {
  item: FragmentType<typeof TODO_ITEM_FIELDS_FRAGMENT>;
}

const VisuallyHiddenInput = styled("input")`
  clip: rect(0 0 0 0);
  clip-path: inset(50%);
  height: 1px;
  overflow: hidden;
  position: absolute;
  bottom: 0;
  left: 0;
  white-space: nowrap;
  width: 1px;
`;

interface UploadButtonProps {
  upload: (file: File) => void;
  attachments: number;
}

function UploadButton({ upload, attachments }: UploadButtonProps) {
  const onChange = (event: FormEvent<HTMLInputElement>) => {
    const { files } = event.currentTarget;
    if (files) upload(files[0]);
  };

  return (
    <IconButton
      component="label"
      aria-label={`upload (${attachments} attachments)`}
    >
      <Badge badgeContent={attachments} variant="plain" size="sm">
        <CloudUploadIcon />
        <VisuallyHiddenInput type="file" onChange={onChange} />
      </Badge>
    </IconButton>
  );
}

interface UploadSnackbarProps {
  error: Error | undefined;
  success: boolean;
  onClose: () => void;
}

function UploadSnackbar({ error, success, onClose }: UploadSnackbarProps) {
  // Use two separate snackbar components to keep the code cleaner.
  // In practice, their open property is mutually exclusive.
  return (
    <>
      <Snackbar color="success" variant="soft" open={success} onClose={onClose}>
        Successfully uploaded file
      </Snackbar>
      <Snackbar color="danger" variant="soft" open={!!error} onClose={onClose}>
        Error uploading: {error?.message}
      </Snackbar>
    </>
  );
}

export default function TodoItem({ item: itemFragment }: Props) {
  const item = useFragment(TODO_ITEM_FIELDS_FRAGMENT, itemFragment);

  const [upload, { reset, data, error }] = useMutation(UPLOAD_TODO_ATTACHMENT, {
    refetchQueries: [GET_ACTIVE_TODOS],
  });

  const uploadButton = (
    <UploadButton
      upload={(file) => void upload({ variables: { file, itemId: item.id } })}
      attachments={item?._count?.attachments ?? 0}
    />
  );

  // The Snackbars need to be outside the endAction to ensure proper layout on
  // the screen (otherwise, it would probably be cleaner to put the entire
  // mutation into the button).

  return (
    <ListItem endAction={uploadButton}>
      <Checkbox label={item.text} checked={item.done} />
      <UploadSnackbar success={!!data} error={error} onClose={reset} />
    </ListItem>
  );
}
