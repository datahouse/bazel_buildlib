import path from "node:path";
import util from "node:util";
import { execFile } from "node:child_process";
import process from "node:process";

import argparse from "argparse";

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

const runTool = (
  tool: string,
  args: string[],
  { workspaceDir, check }: RunConfig,
): Promise<boolean> => {
  const relBin = process.env[`${tool.toUpperCase()}_BIN`];

  if (!relBin) {
    // So far, all tools are mandatory.
    throw new Error(`${tool} not found (this is an it-bazel bug)`);
  }

  // Resolve binary path before switching to workspace directory.
  const bin = path.resolve(relBin);

  console.log(`⏳ ${tool}`);

  return new Promise((res) => {
    execFile(bin, args, { cwd: workspaceDir }, (err, stdout, stderr) => {
      if (err === null) {
        const msg = check ? "format check OK" : "formatting complete";
        console.log(`✅ ${tool} ${msg}`);
        res(true);
      } else {
        const what = check ? "format check" : "formatting";
        const msg = stderr || util.inspect(err);
        console.log(`❌ ${tool} ${what} failed:\n${msg}`);
        res(false);
      }
    });
  });
};

const runPrettier = (cfg: RunConfig) => {
  const mode = cfg.check ? "--check" : "--write";
  return runTool("prettier", [mode, "."], cfg);
};

const runBuildifier = (cfg: RunConfig) => {
  const mode = cfg.check
    ? ["--mode=diff", "--diff_command=diff", "--lint=warn"]
    : ["--mode=fix", "--lint=fix"];

  return runTool("buildifier", [...mode, "--warnings=all", "-r", "."], cfg);
};

const run = async (cfg: RunConfig): Promise<boolean> => {
  const [prettierOK, buildifierOK] = await Promise.all([
    runPrettier(cfg),
    runBuildifier(cfg),
  ]);

  if (prettierOK && buildifierOK) return true;

  if (cfg.check) {
    console.log("Some format checks failed. To fix, run");
    console.log("");
    console.log("    bazel run //:format");
    console.log("");

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
