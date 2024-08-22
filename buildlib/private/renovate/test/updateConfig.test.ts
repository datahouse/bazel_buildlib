import JSON5 from "json5";

import * as extendedMatchers from "jest-extended";

import { updateConfig, Values } from "../src/updateConfig.js";

expect.extend(extendedMatchers);

// Base config we want to fiddle with.
// We allow ourselves any here so it's easy to modify.
// eslint-disable-next-line @typescript-eslint/no-explicit-any
const wantBaseCfg: any = {
  packageRules: [
    {
      matchPackageNames: ["node"],
      allowedVersions: "<= 20.14.2",
    },
  ],
  constraints: {
    pnpm: "8.15.3",
  },
};

const fakeValues: Values = {
  pnpmVersion: "8.15.3",
  newestNodeVersion: "20.14.2",
};

const parsers: [string, (x: unknown) => string, (x: string) => unknown][] = [
  ["json5", JSON5.stringify, JSON5.parse],
  ["json", JSON.stringify, JSON.parse],
];

describe("updateConfig", () => {
  for (const [name, stringify, parse] of parsers) {
    it(`${name} - leave a config untouched`, () => {
      // Add a couple of empty spaces at the end.
      const cfg = `${stringify(wantBaseCfg)}          `;
      expect(updateConfig(cfg, fakeValues)).toEqual(cfg);
    });

    it(`${name} - should update pnpmVersion`, () => {
      const testCfg = structuredClone(wantBaseCfg);
      testCfg.constraints.pnpm = "8.15.2";

      const updated = parse(updateConfig(stringify(testCfg), fakeValues));

      expect(updated).toEqual(wantBaseCfg);
    });

    it(`${name} - should add pnpmVersion`, () => {
      const testCfg = structuredClone(wantBaseCfg);
      testCfg.constraints = {};

      const updated = parse(updateConfig(stringify(testCfg), fakeValues));
      expect(updated).toEqual(wantBaseCfg);
    });

    it(`${name} - should add pnpmVersion and keep other keys`, () => {
      const testCfg = structuredClone(wantBaseCfg);
      testCfg.constraints = { foo: 1 };

      const wantCfg = structuredClone(wantBaseCfg);
      wantCfg.constraints.foo = 1;

      const updated = parse(updateConfig(stringify(testCfg), fakeValues));
      expect(updated).toEqual(wantCfg);
    });

    it(`${name} - should add a packge rule for node`, () => {
      const additionalRule = {
        matchUpdateTypes: ["major"],
        automerge: false,
      };

      const testCfg = structuredClone(wantBaseCfg);
      testCfg.packageRules = [additionalRule];

      const wantCfg = structuredClone(wantBaseCfg);
      wantCfg.packageRules = [additionalRule, ...wantBaseCfg.packageRules];

      const updated = parse(updateConfig(stringify(testCfg), fakeValues));
      expect(updated).toEqual(wantCfg);
    });

    it(`${name} - should allow other packages in the node rule`, () => {
      const testCfg = structuredClone(wantBaseCfg);
      testCfg.packageRules[0].matchPackageNames.push("bob");

      const updated = parse(updateConfig(stringify(testCfg), fakeValues));
      expect(updated).toEqual(testCfg);
    });

    it(`${name} - should work on an empty config`, () => {
      const updated = parse(updateConfig("{}", fakeValues));
      expect(updated).toEqual(wantBaseCfg);
    });
  }
});
