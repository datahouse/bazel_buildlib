import type { Data } from "./data.type.js";

import data from "./data.js";
import untypedData from "./untyped_data.js";

describe("json_to_ts", () => {
  test("typed data", () => {
    // check typing
    const d: Data = data;

    expect(d.a).toEqual([1, 2, 3]);
    expect(d.b).toEqual("foo");
  });

  test("untyped data (i.e. inferred types)", () => {
    // check typing
    const arr: number[] = untypedData.a;
    const str: string = untypedData.b;

    expect(arr).toEqual([1, 2, 3]);
    expect(str).toEqual("foo");
  });
});
