import {
  patchDcServices,
  patchDcServicesFake,
  type ImageInfoWithReference,
  type ImageInfos,
} from "../src/patchDcServices.js";

describe("patcher", () => {
  const fakeImageInfo: ImageInfoWithReference = {
    reference: "fake-ref",
  };

  const fakeImageInfoHot: ImageInfoWithReference = {
    reference: "fake-ref-hot",
    hotReload: {
      hostHomePath: "host/home",
      containerPath: "/container/path",
    },
  };

  const fakeImageInfos: ImageInfos = new Map([
    ["//label", fakeImageInfo],
    ["//hot", fakeImageInfoHot],
  ]);

  it("replaces `bazel-image`", () => {
    const target = {
      services: {
        test: {
          "bazel-image": "//label",
        },
      },
    };

    const want = {
      services: {
        test: {
          image: "fake-ref",
        },
      },
    };

    expect(patchDcServices(fakeImageInfos, target)).toEqual([]);

    expect(target).toEqual(want);
  });

  it("leaves `image` untouched", () => {
    const target = {
      services: {
        test: {
          image: "my-image",
        },
      },
    };

    const want = {
      services: {
        test: {
          image: "my-image",
        },
      },
    };

    expect(patchDcServices(fakeImageInfos, target)).toEqual([]);

    expect(target).toEqual(want);
  });

  it("sets up hot reload", () => {
    const target = {
      services: {
        test: {
          "bazel-image": "//hot",
          volumes: ["my-volume:/etc"],
        },
      },
    };

    const want = {
      services: {
        test: {
          image: "fake-ref-hot",
          volumes: ["my-volume:/etc", "$HOME/host/home:/container/path:ro"],
        },
      },
    };

    expect(patchDcServices(fakeImageInfos, target)).toEqual([]);

    expect(target).toEqual(want);
  });

  it("reports duplicate image definition", () => {
    const target = {
      services: {
        test: {
          "bazel-image": "//label",
          image: "my-image",
        },
      },
    };

    expect(patchDcServices(fakeImageInfos, target)).toEqual([
      "There were problems processing the docker compose file:",
      "- test: has both bazel-image and image",
    ]);
  });

  it("reports missing labels", () => {
    const target = {
      services: {
        test: {
          "bazel-image": "//missing",
        },
      },
    };

    expect(patchDcServices(fakeImageInfos, target)).toEqual([
      "There were problems processing the docker compose file:",
      "- test: unknown label //missing",
      "",
      "Labels found in deps:",
      "- //label",
      "- //hot",
    ]);
  });
});

describe("fake patcher", () => {
  it("replaces `bazel-image`", () => {
    const target = {
      services: {
        test: {
          "bazel-image": "//my-package:unchecked",
        },
      },
    };

    const want = {
      services: {
        test: {
          image: "fake",
        },
      },
    };

    patchDcServicesFake(target);

    expect(target).toEqual(want);
  });

  it("leaves `image` untouched", () => {
    const target = {
      services: {
        test: {
          image: "my-image",
        },
      },
    };

    const want = {
      services: {
        test: {
          image: "my-image",
        },
      },
    };

    patchDcServicesFake(target);

    expect(target).toEqual(want);
  });
});
