import process from "node:process";
import { readFile } from "node:fs/promises";
import argparse from "argparse";
import { z } from "zod";

const packageJsonSchema = z.object({
  type: z.string().optional(),
});

type PackageJson = z.infer<typeof packageJsonSchema>;

const checkPackageJson = (pkg: PackageJson): string[] => {
  const problems: string[] = [];

  if (pkg.type !== "module") {
    problems.push('You must set `"type": "module"`');
  }

  return problems;
};

const main = async () => {
  const parser = new argparse.ArgumentParser({
    description: "package.json checker",
  });

  parser.add_argument("package_json", {
    help: "the package.json to check",
  });

  const args = parser.parse_args();

  const pkgContent = await readFile(args.package_json, "utf8");

  const validatedPkg = packageJsonSchema.parse(JSON.parse(pkgContent));

  const problems = checkPackageJson(validatedPkg);

  if (problems.length > 0) {
    console.error("There are problems with your package.json");
    problems.forEach((p) => console.error(`- ${p}`));
    process.exit(2);
  }
};

await main();
