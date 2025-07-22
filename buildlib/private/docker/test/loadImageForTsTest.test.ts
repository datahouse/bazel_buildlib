import loadNodeTestImage from "./load_node_test_image.js";

it("should load the docker image", async () => {
  expect(await loadNodeTestImage()).not.toEqual("");
});
