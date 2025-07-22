import path from "node:path";
import process from "node:process";

import { opendir } from "node:fs/promises";

import argparse from "argparse";

import { execFileWithCode } from "../../js-lib/src/execFileWithCode.js";

const parseArgs = () => {
  const parser = new argparse.ArgumentParser({
    description: "Datahouse Bazel formatter",
  });

  parser.add_argument("--check", {
    help: "Check that formatting is correct",
    action: argparse.BooleanOptionalAction,
    default: false,
  });

  return parser.parse_args() as { check: boolean };
};

const loadEnv = () => {
  const workspaceDir = process.env.BUILD_WORKSPACE_DIRECTORY;

  if (!workspaceDir) {
    throw new Error(
      "BUILD_WORKSPACE_DIRECTORY is not set. Are you running under `bazel run`?",
    );
  }

  return { workspaceDir };
};

interface RunConfig {
  workspaceDir: string;
  check: boolean;
}

interface RunToolOptions {
  tool: string;
  args: string[];
  mandatory: boolean;
  explicitFilesPromise?: Promise<string[]>;
  cfg: RunConfig;
}

const runTool = async ({
  tool,
  args,
  mandatory,
  explicitFilesPromise,
  cfg: { workspaceDir, check },
}: RunToolOptions): Promise<boolean> => {
  const relBin = process.env[`${tool.toUpperCase()}_BIN`];

  if (!relBin) {
    if (!mandatory) return true;
    throw new Error(`${tool} not found (this is an it-bazel bug)`);
  }

  // Resolve binary path before switching to workspace directory.
  const bin = path.resolve(relBin);

  console.log(`⏳ ${tool}`);

  // Only await files now, so we show that the tool is running.
  // Note that awaiting undefined conveniently returns undefined.
  const explicitFiles = await explicitFilesPromise;

  const fullArgs = args.concat(explicitFiles ?? []);

  // Do not run tools that require explicit files if there are no files.
  const shouldRun = explicitFiles === undefined || explicitFiles.length > 0;

  const { code, stderr } = shouldRun
    ? await execFileWithCode(bin, fullArgs, { cwd: workspaceDir })
    : { code: 0, stderr: "" };

  const ok = code === 0;

  if (ok) {
    const msg = check ? "format check OK" : "formatting complete";
    console.log(`✅ ${tool} ${msg}`);
  } else {
    const what = check ? "format check" : "formatting";
    console.log(`❌ ${tool} ${what} failed:\n${stderr}`);
  }

  return ok;
};

const runPrettier = (cfg: RunConfig) =>
  runTool({
    tool: "prettier",
    args: [cfg.check ? "--check" : "--write", "."],
    mandatory: true,
    cfg,
  });

const runBuildifier = (cfg: RunConfig) => {
  const mode = cfg.check
    ? ["--mode=diff", "--diff_command=diff", "--lint=warn"]
    : ["--mode=fix", "--lint=fix"];

  return runTool({
    tool: "buildifier",
    args: [...mode, "--warnings=all", "-r", "."],
    mandatory: true,
    cfg,
  });
};

const findJavaFiles = async (dir: string) => {
  const res: string[] = [];
  for await (const e of await opendir(dir, { recursive: true })) {
    if (e.isFile() && e.name.endsWith(".java"))
      res.push(path.join(e.parentPath, e.name));
  }
  return res;
};

const runGoogleJavaFormat = async (cfg: RunConfig) => {
  const args = cfg.check
    ? ["--dry-run", "--set-exit-if-changed"]
    : ["--replace"];

  const explicitFilesPromise = findJavaFiles(cfg.workspaceDir);

  return runTool({
    tool: "google_java_format",
    args,
    mandatory: false,
    explicitFilesPromise,
    cfg,
  });
};

const allTrue = async (...promises: Promise<boolean>[]): Promise<boolean> => {
  const values = await Promise.all(promises);
  return values.every((x) => x); // poor man's "all"
};

const run = async (cfg: RunConfig): Promise<boolean> => {
  // Keep the buildifier result separately: We want to provide additional help if it fails.
  const buildifierOKPromise = runBuildifier(cfg);

  const ok = await allTrue(
    buildifierOKPromise,
    runPrettier(cfg),
    runGoogleJavaFormat(cfg),
  );

  if (ok) return true;

  if (cfg.check) {
    console.log("Some format checks failed. To fix, run");
    console.log("");
    console.log("    bazel run //:format");
    console.log("");

    const buildifierOK = await buildifierOKPromise;
    if (!buildifierOK) {
      console.log(
        "Attention: Not all buildifier checks can be fixed automatically.",
      );
    }
  }

  return false;
};

const main = async () => {
  const { check } = parseArgs();
  const { workspaceDir } = loadEnv();

  const ok = await run({ check, workspaceDir });

  process.exit(ok ? 0 : 1);
};

await main();
