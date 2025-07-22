import path from "node:path";

export const inferRepositoryPrefix = (
  env: Record<string, string | undefined>,
) => {
  const getEnv = (n: string): string => {
    const v = env[n];
    if (v !== undefined) return v;
    throw new Error(`Couldn't find ${n} in the environment`);
  };

  const repoName = getEnv("DRONE_REPO_NAME");
  const droneWorkspace = getEnv("DRONE_WORKSPACE");
  const bazelWorkspace = getEnv("BUILD_WORKSPACE_DIRECTORY");

  return path.join(
    "docker.datarepo.ch",
    repoName.toLowerCase(),
    path.relative(droneWorkspace, bazelWorkspace),
  );
};
