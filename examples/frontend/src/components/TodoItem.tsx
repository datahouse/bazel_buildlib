import { useState } from "react";

import { ListItem, Checkbox, IconButton, Badge } from "@mui/joy";

import { AttachFileOutlined, FileUploadOutlined } from "@mui/icons-material";

import { FragmentType } from "@apollo/client";

import { useMutation, useSuspenseFragment } from "@apollo/client/react";

import { gql } from "../../gql/index.js";
import { TodoItemFieldsFragment } from "../../gql/graphql.js";

import { GET_ACTIVE_TODOS, GET_ATTACHMENTS } from "../queries.js";

import AttachmentsModal from "./AttachmentsModal.js";
import UploadInput from "./UploadInput.js";
import { MutationResultSnackbar } from "./MutationSnackbar.js";

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

// exported for testing
export const DELETE_TODO_ATTACHMENT = gql(`
  mutation deleteTodoAttachment ($id: Int!) {
    deleteAttachment (
      id: $id
    )
  }
`);

export interface Props {
  item: FragmentType<TodoItemFieldsFragment>;
}

interface AttachmentsButtonProps {
  attachmentCount: number;
  itemId: number;
  upload: (file: File) => void;
  deleteAttachment: (attachmentId: number) => void;
}

function AttachmentsButton({
  attachmentCount,
  itemId,
  upload,
  deleteAttachment,
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
        deleteAttachment={deleteAttachment}
      />
    </>
  );
}

export default function TodoItem({ item: itemFragment }: Props) {
  const { data: item } = useSuspenseFragment({
    fragment: TODO_ITEM_FIELDS_FRAGMENT,
    from: itemFragment,
  });

  const refetchQueries = [GET_ACTIVE_TODOS, GET_ATTACHMENTS];

  const [upload, uploadResult] = useMutation(UPLOAD_TODO_ATTACHMENT, {
    refetchQueries,
  });

  const [deleteAttachment, deleteAttachmentResult] = useMutation(
    DELETE_TODO_ATTACHMENT,
    { refetchQueries },
  );

  const execAttachmentDelete = (id: number) =>
    void deleteAttachment({ variables: { id } });

  const attachmentCount = item?._count?.attachments ?? 0;

  const execUpload = (file: File) =>
    void upload({ variables: { file, itemId: item.id } });

  const endAction =
    attachmentCount > 0 ? (
      <AttachmentsButton
        itemId={item.id}
        attachmentCount={attachmentCount}
        upload={execUpload}
        deleteAttachment={execAttachmentDelete}
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
      <MutationResultSnackbar
        result={uploadResult}
        successMessage="File uploaded successfully"
        errorMessage="Error uploading file"
      />
      <MutationResultSnackbar
        result={deleteAttachmentResult}
        successMessage="Attachment deleted successfully"
        errorMessage="Error deleting attachment"
      />
    </ListItem>
  );
}
