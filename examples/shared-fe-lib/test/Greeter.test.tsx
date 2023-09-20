import "@testing-library/jest-dom";

import React from "react";
import { render, screen } from "@testing-library/react";

import Greeter from "../src/Greeter";

test("renders the Greeter", () => {
  render(<Greeter />);
  const linkElement = screen.getByText(/Hello from/);
  expect(linkElement).toBeInTheDocument();
});
