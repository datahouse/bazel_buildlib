import loadMyImage from "./load_my_image.js";

it("should load the docker image", async () => {
  expect(await loadMyImage()).not.toEqual("");
});
