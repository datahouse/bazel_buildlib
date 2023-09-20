import fs from "node:fs/promises";

export interface HotReloadInfo {
  files: string[];
  hostHomePath: string;
  containerPath: string;
}

export type ImageInfo =
  | { digestFile: string; loadCmd: string; hotReload?: HotReloadInfo }
  | { reference: string };

export type ImageInfos = { [label: string]: ImageInfo };

export const readImageInfos = async (path: string): Promise<ImageInfos> =>
  JSON.parse(await fs.readFile(path, "utf8")) as ImageInfos;
