import loadTestImage from "./load_test_image.js";

it("should load the docker image", async () => {
  expect(await loadTestImage()).not.toEqual("");
});
