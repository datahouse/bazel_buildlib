import { useState } from "react";

import { ListItem, Checkbox, IconButton, Snackbar, Badge } from "@mui/joy";

import { AttachFileOutlined, FileUploadOutlined } from "@mui/icons-material";

import {
  useMutation,
  MutationResult,
  FragmentType,
  useSuspenseFragment,
} from "@apollo/client";

import { gql } from "../../gql/index.js";
import { TodoItemFieldsFragment } from "../../gql/graphql.js";

import { GET_ACTIVE_TODOS, GET_ATTACHMENTS } from "../queries.js";

import AttachmentsModal from "./AttachmentsModal.js";
import UploadInput from "./UploadInput.js";

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
  item: FragmentType<TodoItemFieldsFragment>;
}

interface UploadSnackbarProps {
  result: MutationResult<unknown>;
}

function UploadSnackbar({ result }: UploadSnackbarProps) {
  const onClose = () => result.reset();
  const error = !!result.error;
  const success = !!result.data;

  // Use two separate snackbar components to keep the code cleaner.
  // In practice, their open property is mutually exclusive.
  return (
    <>
      <Snackbar color="success" variant="soft" open={success} onClose={onClose}>
        Successfully uploaded file
      </Snackbar>
      <Snackbar color="danger" variant="soft" open={error} onClose={onClose}>
        Error uploading: {result.error?.message}
      </Snackbar>
    </>
  );
}

interface AttachmentsButtonProps {
  attachmentCount: number;
  itemId: number;
  upload: (file: File) => void;
}

function AttachmentsButton({
  attachmentCount,
  itemId,
  upload,
}: AttachmentsButtonProps) {
  const [open, setOpen] = useState(false);

  return (
    <>
      <IconButton
        onClick={() => setOpen(true)}
        aria-label={`${attachmentCount} attachments`}
      >
        <Badge badgeContent={attachmentCount} variant="plain" size="sm">
          <AttachFileOutlined />
        </Badge>
      </IconButton>
      <AttachmentsModal
        open={open}
        onClose={() => setOpen(false)}
        itemId={itemId}
        upload={upload}
      />
    </>
  );
}

export default function TodoItem({ item: itemFragment }: Props) {
  const { data: item } = useSuspenseFragment({
    fragment: TODO_ITEM_FIELDS_FRAGMENT,
    from: itemFragment,
  });

  const [upload, uploadResult] = useMutation(UPLOAD_TODO_ATTACHMENT, {
    refetchQueries: [GET_ACTIVE_TODOS, GET_ATTACHMENTS],
  });

  const attachmentCount = item?._count?.attachments ?? 0;

  const execUpload = (file: File) =>
    void upload({ variables: { file, itemId: item.id } });

  const endAction =
    attachmentCount > 0 ? (
      <AttachmentsButton
        itemId={item.id}
        attachmentCount={attachmentCount}
        upload={execUpload}
      />
    ) : (
      <IconButton component="label" aria-label="upload attachment">
        <FileUploadOutlined />
        <UploadInput upload={execUpload} />
      </IconButton>
    );

  // The Snackbars need to be outside the endAction to ensure proper layout on
  // the screen (otherwise, it would probably be cleaner to put the entire
  // mutation into the button).

  return (
    <ListItem endAction={endAction}>
      <Checkbox label={item.text} checked={item.done} />
      <UploadSnackbar result={uploadResult} />
    </ListItem>
  );
}
