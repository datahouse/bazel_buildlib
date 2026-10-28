import { readFile } from "node:fs/promises";

export interface WorkspaceStatus {
  commit: string;
  source: string;
  url: string;
  tag: string;
  buildHost: string;
  buildUser: string;
  buildTime: Date;
}

const parseLine = (line: string): [string, string] => {
  const [key, ...rest] = line.split(" ");
  if (!key) throw new Error(`unexpected line: '${line}'`);
  return [key, rest.join(" ")];
};

const parse = (data: string) =>
  new Map(
    data
      .split("\n")
      .filter((line) => line !== "")
      .map(parseLine),
  );

const get = (status: Map<string, string>, name: string) => {
  const v = status.get(name);

  if (v === undefined) {
    throw new Error(
      `couldn't find workspace status ${name}, did you set --workspace_status_command`,
    );
  }

  if (v === "") {
    throw new Error(`workspace status ${name} is empty, this is not allowed`);
  }

  return v;
};

const getTimestamp = (status: Map<string, string>, name: string) => {
  const v = get(status, name);
  const seconds = Number(v);

  if (!Number.isInteger(seconds)) {
    throw new Error(`workspace status ${name} is not a timestamp: '${v}'`);
  }

  return new Date(1000 * seconds);
};

export const loadWorkspaceStatus = async (
  stableStatusFile: string,
  volatileStatusFile: string,
): Promise<WorkspaceStatus> => {
  const stable = parse(await readFile(stableStatusFile, "utf8"));
  const volatile = parse(await readFile(volatileStatusFile, "utf8"));

  return {
    commit: get(stable, "STABLE_GIT_COMMIT"),
    source: get(stable, "STABLE_GIT_REPO_URL"),
    url: get(stable, "STABLE_WEB_REPO_URL"),
    tag: get(stable, "BUILD_EMBED_LABEL"),
    buildHost: get(stable, "BUILD_HOST"),
    buildUser: get(stable, "BUILD_USER"),
    buildTime: getTimestamp(volatile, "BUILD_TIMESTAMP"),
  };
};
