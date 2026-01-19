import { spawn } from "node:child_process";
// Promisified variant of spawn that always inherits IO.
export const spawnInheritIO = async (
  command: string,
  ...args: string[]
): Promise<number> =>
  new Promise((res, rej) => {
    const childProcess = spawn(command, args, { stdio: "inherit" });

    childProcess.on("error", rej);
    childProcess.on("close", res);
  });

export default spawnInheritIO;
