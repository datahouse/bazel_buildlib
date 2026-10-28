import { join } from "node:path";

const basePath = (homeDir: string, subsystem: string, composeProject: string) =>
  join(homeDir, ".cache", "dh-buildlib", subsystem, composeProject);

export const hotCachePath = (
  homeDir: string,
  composeProject: string,
  subPath: string,
): string => join(basePath(homeDir, "dc-hot", composeProject), subPath);

export const portFilePath = (homeDir: string, composeProject: string): string =>
  join(basePath(homeDir, "dc-zot", composeProject), "port");
