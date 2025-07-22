import { Suspense, type ReactNode } from "react";
import { ErrorBoundary, FallbackProps } from "react-error-boundary";
import { Alert } from "@mui/joy";

export interface Props {
  itemDesc: string;
  children: ReactNode;
}

// A basic combined supsense and error boundary.
// Probably too simplistic for more advanced use cases, but a simple enough
// drop-in when some basic loading / error handling is required.
export default function LoadBoundary({ itemDesc, children }: Props) {
  const errorRender = ({ error }: FallbackProps) => (
    <Alert color="danger" variant="soft">
      Error: {error.message}
    </Alert>
  );

  const loading = (
    <Alert color="warning" variant="soft">
      Loading {itemDesc}...
    </Alert>
  );

  return (
    <ErrorBoundary fallbackRender={errorRender}>
      <Suspense fallback={loading}>{children}</Suspense>
    </ErrorBoundary>
  );
}
