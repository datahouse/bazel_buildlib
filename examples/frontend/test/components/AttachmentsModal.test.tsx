import "@testing-library/jest-dom";

import { render as rawRender, act, screen } from "@testing-library/react";
import { MockedProvider, MockedResponse } from "@apollo/client/testing";

import AttachmentsModal from "../../src/components/AttachmentsModal.js";

import { GET_ATTACHMENTS } from "../../src/queries.js";

const render = (mocks: MockedResponse[]) => {
  // General note: Uploads are tested in TodoLists.test.tsx
  const ignore = () => {};

  return act(() =>
    rawRender(
      <MockedProvider mocks={mocks}>
        <AttachmentsModal open itemId={10} upload={ignore} onClose={ignore} />
      </MockedProvider>,
    ),
  );
};

test("renders a list of attachments", async () => {
  const mocks = [
    {
      request: {
        query: GET_ATTACHMENTS,
        variables: { itemId: 10 },
      },
      result: {
        data: {
          todoAttachments: [
            {
              id: 1,
              filename: "file1.txt",
              uuid: "00000000-0000-0000-0000-000000000000",
            },
            {
              id: 2,
              filename: "file2.txt",
              uuid: "11111111-1111-1111-1111-111111111111",
            },
          ],
        },
      },
    },
  ];

  await render(mocks);

  const files = await screen.findAllByText(/^file.+/);

  expect(files).toHaveLength(2);
  expect(files[0]).toHaveTextContent("file1.txt");
  expect(files[0]).toHaveAttribute(
    "href",
    "/blob/todoAttachment/00000000-0000-0000-0000-000000000000",
  );
  expect(files[1]).toHaveTextContent("file2.txt");
  expect(files[1]).toHaveAttribute(
    "href",
    "/blob/todoAttachment/11111111-1111-1111-1111-111111111111",
  );
});

test("reports loading", async () => {
  const mocks = [
    {
      request: {
        query: GET_ATTACHMENTS,
        variables: { itemId: 10 },
      },
      delay: Infinity,
    },
  ];

  await render(mocks);

  expect(
    await screen.findByText("Loading the attachments..."),
  ).toBeInTheDocument();
});

test("reports errors", async () => {
  const mocks = [
    {
      request: {
        query: GET_ATTACHMENTS,
        variables: { itemId: 10 },
      },
      error: new Error("Boom!"),
    },
  ];

  await render(mocks);

  expect(await screen.findByText("Error: Boom!")).toBeInTheDocument();
});
