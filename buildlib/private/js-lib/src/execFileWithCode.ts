import { execFile, type ExecFileOptions } from "node:child_process";

export interface ExecResult {
  code: number;
  stdout: string;
  stderr: string;
}

// execFile which isn't 0 exit code biased:
// The resulting promise **doesn't** reject if the exit code is non-zero.
export const execFileWithCode = (
  file: string,
  args: string[] = [],
  opts: ExecFileOptions = {},
): Promise<ExecResult> =>
  new Promise((res, rej) => {
    execFile(file, args, opts, (error, stdout, stderr) => {
      if (!error) res({ code: 0, stdout, stderr });
      else if (typeof error.code === "number")
        res({ code: error.code, stdout, stderr });
      else rej(error);
    });
  });
