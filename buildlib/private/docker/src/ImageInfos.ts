import fs from "node:fs/promises";

export interface HotReloadInfo {
  files: string[];
  hostHomePath: string;
  containerPath: string;
}

export interface ImageInfo {
  keys: string[];
  ociDir: string;
  ociDirShort: string;
  hotReload?: HotReloadInfo;
}

export const readImageInfos = async (path: string): Promise<ImageInfo[]> =>
  JSON.parse(await fs.readFile(path, "utf8")) as ImageInfo[];
