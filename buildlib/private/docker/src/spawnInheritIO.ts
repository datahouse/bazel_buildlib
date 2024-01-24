import { spawn } from "node:child_process";

// Promisified variant of spawn that always inherits IO.
export const spawnInheritIO = async (
  command: string,
  ...args: string[]
): Promise<void> =>
  new Promise((res, rej) => {
    const childProcess = spawn(command, args, { stdio: "inherit" });

    childProcess.on("error", rej);
    childProcess.on("close", (code) => {
      if (code !== 0) rej(new Error(`${command} exited with code ${code}`));
      else res();
    });
  });

export default spawnInheritIO;
