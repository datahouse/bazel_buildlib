import "@testing-library/jest-dom";

import { render, screen, fireEvent } from "@testing-library/react";
import { MockedProvider } from "@apollo/client/testing";

import type { TodoList } from "../src/gql/graphql.js";

import { GET_ACTIVE_TODOS } from "../src/queries.js";
import { UPLOAD_TODO_ATTACHMENT } from "../src/components/TodoItem.js";

import TodoLists from "../src/TodoLists.js";

// Helper types to build the fake data:
//
// We cannot use the type generated by the GET_ACTIVE_TODOS query, since it
// indirects via fragments (to hide the fragment fields).
//
// Instead, we use the types generated from the schema, plus some type hackery
// to make all fields optional. This ensures that if we set a field, it is of
// the correct type (but if we forget one, we'll only catch it when running the test).

type PartialDeep<T> = T extends object
  ? {
      [P in keyof T]?: PartialDeep<T[P]>;
    }
  : T;

interface GetActiveTodosData {
  todoLists: PartialDeep<TodoList>[];
}

// A note about the __typename fields:
// - They are required to make fragments work correctly.
// - They are typically generated by the GraphQL server, but the MockedProvider
//   doesn't do this automatcially.
// - The types verify that the strings are correct (via constant types).

const fakeData = (): GetActiveTodosData => ({
  todoLists: [
    {
      __typename: "TodoList",
      name: "list 1",
      id: 3,
      items: [
        {
          __typename: "TodoItem",
          id: 1,
          text: "item 1.1",
          done: false,
          _count: {
            attachments: 2,
          },
        },
      ],
    },
    {
      __typename: "TodoList",
      name: "list 2",
      id: 1,
      items: [
        {
          __typename: "TodoItem",
          id: 5,
          text: "item 2.1",
          done: true,
          _count: {
            attachments: 0,
          },
        },
      ],
    },
    {
      __typename: "TodoList",
      name: "list 3",
      id: 42,
      items: [],
    },
  ],
});

const renderWithData = (data: GetActiveTodosData) => {
  const mocks = [
    {
      request: { query: GET_ACTIVE_TODOS },
      result: { data },
    },
  ];

  render(
    <MockedProvider mocks={mocks}>
      <TodoLists />
    </MockedProvider>,
  );
};

test("renders a list of the todo lists", async () => {
  renderWithData(fakeData());

  const lists = await screen.findAllByText(/^list.+/);

  expect(lists).toHaveLength(3);
  expect(lists[0]).toHaveTextContent("list 1");
  expect(lists[1]).toHaveTextContent("list 2");
  expect(lists[2]).toHaveTextContent("list 3");
});

test("collapses lists", async () => {
  renderWithData(fakeData());

  // Wait until lists are rendered.
  const lists = await screen.findAllByText(/^list.+/);

  // Check no items are present.
  expect(screen.queryAllByText(/^item.+$/)).toHaveLength(0);

  // Expand the list.
  fireEvent.click(lists[0]);

  // Check the item is there now.
  await screen.findByText("item 1.1");

  // Check list 2 is *not* expanded.
  expect(screen.queryByText("item 2.1")).toBeNull();
});

test("shows attachment count", async () => {
  renderWithData(fakeData());

  // Expand the first list.
  fireEvent.click(await screen.findByText("list 1"));

  const badge = await screen.findByLabelText(/2 attachments/);

  expect(badge).toBeInTheDocument();
});

test("upload", async () => {
  const preUploadData = fakeData();
  const postUploadData = fakeData();

  const itemToUploadFor = postUploadData.todoLists[0].items![0]!;
  itemToUploadFor._count!.attachments! += 1;

  const fakeFile = new File(["content"], "test.txt", { type: "foo" });

  const uploadMock = jest.fn();
  uploadMock.mockReturnValue({
    data: { uploadTodoAttachment: 123 },
  });

  const mocks = [
    {
      request: { query: GET_ACTIVE_TODOS },
      result: { data: preUploadData },
    },
    {
      request: {
        query: UPLOAD_TODO_ATTACHMENT,
        variables: { file: fakeFile, itemId: itemToUploadFor.id },
      },
      result: uploadMock,
    },
    {
      request: { query: GET_ACTIVE_TODOS },
      result: { data: postUploadData },
    },
  ];

  render(
    <MockedProvider mocks={mocks}>
      <TodoLists />
    </MockedProvider>,
  );

  // Expand the first list.
  fireEvent.click(await screen.findByText("list 1"));

  const uploadContainer = await screen.findByLabelText(/^upload/);
  const upload = uploadContainer.querySelector("[type='file']");

  expect(upload).not.toBeUndefined();

  // Simulate an upload.
  // Non-null assertion due to:
  // https://github.com/DefinitelyTyped/DefinitelyTyped/issues/41179
  fireEvent.change(upload!, { target: { files: [fakeFile] } });

  // Check we update the attachment count.
  await screen.findByLabelText(/3 attachments/);

  expect(uploadMock).toHaveBeenCalledTimes(1);
});

test("reports loading", async () => {
  const mocks = [
    {
      request: { query: GET_ACTIVE_TODOS },
      delay: Infinity, // load forever
    },
  ];

  render(
    <MockedProvider mocks={mocks} addTypename={false}>
      <TodoLists />
    </MockedProvider>,
  );

  expect(await screen.findByText("Loading your TODOs...")).toBeInTheDocument();
});

test("reports an error", async () => {
  const mocks = [
    {
      request: { query: GET_ACTIVE_TODOS },
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
