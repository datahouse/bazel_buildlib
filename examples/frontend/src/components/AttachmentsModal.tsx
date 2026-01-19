import { FileUploadOutlined } from "@mui/icons-material";

import {
  Button,
  Modal,
  ModalDialog,
  ModalClose,
  DialogTitle,
  DialogContent,
} from "@mui/joy";

import AttachmentsList from "./AttachmentsList.js";
import LoadBoundary from "./LoadBoundary.js";

import UploadInput from "./UploadInput.js";

interface Props {
  open: boolean;
  onClose: () => void;
  itemId: number;
  upload: (file: File) => void;
  deleteAttachment: (attachmentId: number) => void;
}

export default function AttachmentsModal({
  upload,
  itemId,
  open,
  onClose,
  deleteAttachment,
}: Props) {
  return (
    <Modal open={open} onClose={onClose}>
      <ModalDialog>
        <DialogTitle>Attachments</DialogTitle>
        <ModalClose />
        <DialogContent>
          <LoadBoundary itemDesc="the attachments">
            <AttachmentsList
              itemId={itemId}
              deleteAttachment={deleteAttachment}
            />
          </LoadBoundary>
          <Button
            component="label"
            variant="outlined"
            color="neutral"
            startDecorator={<FileUploadOutlined />}
          >
            Upload Attachment
            <UploadInput upload={upload} />
          </Button>
        </DialogContent>
      </ModalDialog>
    </Modal>
  );
}
