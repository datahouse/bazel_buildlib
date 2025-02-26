import { z } from "zod";
import semver from "semver";

const EXACT_VERSION_LINK =
  "https://docs.npmjs.com/cli/v6/using-npm/semver#versions";

// NOTE: We must pass the field name as a string because we can't use superRefine with z.undefined().
// z.undefined() fails immediately if the value is not undefined, which means superRefine cannot access the field name dynamically.

const disallow = (fieldName: string, reason: string) => {
  const message = `Do not set \`${fieldName}\`: ${reason}`;
  return z.undefined({ message });
};

const disallowPub = (fieldName: string) =>
  disallow(
    fieldName,
    "it is only relevant for publishing npm packages which is unsupported.",
  );

const exactDependency = z.string().superRefine((val, ctx) => {
  const pkg = ctx.path[ctx.path.length - 1];
  if (!semver.valid(val)) {
    ctx.addIssue({
      code: z.ZodIssueCode.custom,
      message: `Dependency "${pkg}" does not use an exact version. Current: "${val}". An exact version is necessary. See: ${EXACT_VERSION_LINK}`,
    });
  }
});

const dependencySchema = z.record(exactDependency).optional();

// Rationale: We want a minimal package.json which is used for installing packages.
// We disallow users to set fields that are not relevant for our use-case.
// Find single fields here:  https://docs.npmjs.com/cli/v10/configuring-npm/package-json
// NOTE: "type": "module" deviates from that documentation because of #325

const packageJsonSchema = z.object({
  type: z.literal("module", { message: 'You must set `"type:" "module"`' }),
  name: disallowPub("name"),
  version: disallow(
    "version",
    "Use `@dh_buildlib//my-version`. Check `buildlib/README.md` for more information.",
  ),
  description: disallowPub("description"),
  keywords: disallowPub("keywords"),
  homepage: disallowPub("homepage"),
  bugs: disallowPub("bugs"),
  license: disallowPub("license"),
  author: disallowPub("author"),
  contributors: disallowPub("contributors"),
  funding: disallowPub("funding"),
  files: disallowPub("files"),
  main: disallowPub("main"),
  browser: disallowPub("browser"),
  bin: disallow(
    "bin",
    "Use the `js_binary` or `js_run_binary` macros. Check `https://docs.aspect.build/rulesets/aspect_rules_js/` for more information.",
  ),
  man: disallowPub("man"),
  directories: disallowPub("directories"),
  repository: disallowPub("repository"),
  scripts: disallow(
    "scripts",
    "Use the `js_binary` or `js_run_binary` macros. Check `https://docs.aspect.build/rulesets/aspect_rules_js/` for more information.",
  ),
  config: disallowPub("config"),
  dependencies: dependencySchema,
  devDependencies: dependencySchema,
  peerDependencies: disallowPub("peerDependencies"),
  peerDependenciesMeta: disallowPub("peerDependenciesMeta"),
  bundleDependencies: disallowPub("bundleDependencies"),
  optionalDependencies: disallowPub("optionalDependencies"),
  overrides: dependencySchema,
  engines: disallow("engines", "Node.js versions are managed through `.nvmrc`"),
  cpu: disallowPub("cpu"),
  private: disallowPub("private"),
  publishConfig: disallowPub("publishConfig"),
  workspaces: disallow(
    "workspaces",
    "Use the `ts_library` macro provided in `dh_buildlib`. Check `buildlib/docs/ts.md` for more information.",
  ),
});

export const packageJsonProblems = (pkg: unknown): string[] => {
  const problems = packageJsonSchema.safeParse(pkg);
  if (problems.success) {
    return [];
  }
  return problems.error.errors.map((issue) => issue.message);
};
