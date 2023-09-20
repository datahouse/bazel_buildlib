import "@testing-library/jest-dom";

import React from "react";
import { render, screen } from "@testing-library/react";
import { MockedProvider } from "@apollo/client/testing";

import TodoLists, { GET_ACTIVE_TODO_LISTS } from "../src/TodoLists";

test("renders a list of the todo lists", async () => {
  const mocks = [
    {
      request: { query: GET_ACTIVE_TODO_LISTS },
      result: {
        data: {
          todoLists: [
            { name: "list 1", id: 3 },
            { name: "list 2", id: 1 },
            { name: "list 3", id: 42 },
          ],
        },
      },
    },
  ];

  render(
    <MockedProvider mocks={mocks} addTypename={false}>
      <TodoLists />
    </MockedProvider>,
  );

  expect(
    await screen.findByText("Loading your todo lists..."),
  ).toBeInTheDocument();

  const lists = await screen.findAllByText(/^list.+/);

  expect(lists).toHaveLength(3);
  expect(lists[0]).toHaveTextContent("list 1");
  expect(lists[1]).toHaveTextContent("list 2");
  expect(lists[2]).toHaveTextContent("list 3");
});

test("reports an error", async () => {
  const mocks = [
    {
      request: { query: GET_ACTIVE_TODO_LISTS },
      error: new Error("Boom!"),
    },
  ];

  render(
    <MockedProvider mocks={mocks} addTypename={false}>
      <TodoLists />
    </MockedProvider>,
  );

  expect(await screen.findByText("Error: Boom!")).toBeInTheDocument();
});
