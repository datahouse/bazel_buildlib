import "@testing-library/jest-dom";

import React from "react";
import { render, screen } from "@testing-library/react";
import { MockedProvider } from "@apollo/client/testing";

import App from "../src/App";

test("renders the app", () => {
  // Just inject a MockedProvider without any mocks.
  // All gql queries will fail, but the app should still render.

  render(
    <MockedProvider>
      <App />
    </MockedProvider>,
  );
  const elem = screen.getByText(/This is the application/);
  expect(elem).toBeInTheDocument();
});
