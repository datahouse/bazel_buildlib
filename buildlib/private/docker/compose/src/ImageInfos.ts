import fs from "node:fs/promises";

export interface HotReloadInfo {
  files: string[];
  hostSubPath: string;
  containerPath: string;
}

export interface ImageInfo {
  imageKey: string; // bazel label for the image
  zotRepoName: string; // zot repository name to serve the image at
  ociDir: string;
  ociDirShort: string;
  hotReload?: HotReloadInfo;
}

export const readImageInfos = async (path: string): Promise<ImageInfo[]> =>
  JSON.parse(await fs.readFile(path, "utf8")) as ImageInfo[];
