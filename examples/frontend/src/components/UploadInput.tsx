import { styled } from "@mui/joy";

import type { FormEvent } from "react";

import { allowedMimeTypes } from "../../../shared-lib/src/allowed-mimetypes.js";

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

export interface Props {
  upload: (file: File) => void;
}

const accept = allowedMimeTypes.join(",");

export default function UploadInput({ upload }: Props) {
  const onChange = (event: FormEvent<HTMLInputElement>) => {
    const { files } = event.currentTarget;
    if (files) upload(files[0]);
  };

  return (
    <VisuallyHiddenInput accept={accept} type="file" onChange={onChange} />
  );
}
