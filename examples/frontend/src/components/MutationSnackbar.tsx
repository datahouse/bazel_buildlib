import type { useMutation } from "@apollo/client/react";
import { Snackbar } from "@mui/joy";

interface MutationSnackbarProps {
  result: useMutation.Result<unknown>;
  successMessage: string;
  errorMessage: string;
}

export function MutationResultSnackbar({
  result,
  successMessage,
  errorMessage,
}: MutationSnackbarProps) {
  const onClose = () => result.reset();
  const error = !!result.error;
  const success = !!result.data;

  // Use two separate snackbar components to keep the code cleaner.
  // In practice, their open property is mutually exclusive.
  return (
    <>
      <Snackbar color="success" variant="soft" open={success} onClose={onClose}>
        {successMessage}
      </Snackbar>
      <Snackbar color="danger" variant="soft" open={error} onClose={onClose}>
        {`${errorMessage}: ${result.error?.message}`}
      </Snackbar>
    </>
  );
}
