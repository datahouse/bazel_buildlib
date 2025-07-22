// Just a couple of mimetypes to allow.
//
// Because we send files and their mimetypes back to the browser, they are
// somewhat security sensitive.
//
// We define the list of allowed types in the shared lib, so we can use them for
// validation in both the frontend and the backend.
export const allowedMimeTypes = [
  "image/png",
  "image/jpeg",
  "text/plain",
  "text/markdown",
  "text/csv",
];
