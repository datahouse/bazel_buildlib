import "@testing-library/jest-dom";

import { render, screen } from "@testing-library/react";

import Footer from "../src/Footer.js";

test("renders the Footer", () => {
  render(<Footer />);
  const linkElement = screen.getByText(/it-bazel example/);
  expect(linkElement).toBeInTheDocument();
});
