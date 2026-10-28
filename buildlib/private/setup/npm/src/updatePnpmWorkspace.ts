import { z } from "zod";

import { load } from "js-yaml";

const schema = z
  .object({
    saveExact: z.literal(
      true,
      "You must set saveExact to true in pnpm-workspace.yaml",
    ),
    hoist: z.literal(
      false,
      "You must set hoist to false in pnpm-workspace.yaml.\n" +
        "See https://github.com/aspect-build/rules_js/blob/main/docs/pnpm.md#hoisting",
    ),
  })
  .partial();

export type Result =
  | { updated: string } // updated pnpm workspace
  | { problems: string[] }; // problems with (current) pnpm workspace

export const updatePnpmWorkspace = (input: string): Result => {
  const result = schema.safeParse(load(input));

  if (!result.success) {
    const problems = result.error.issues.map(({ message }) => message);
    return { problems };
  }

  const { data } = result;

  let updated = input;

  if (!("saveExact" in data)) updated += "saveExact: true\n";
  if (!("hoist" in data)) updated += "hoist: false\n";

  return { updated };
};
