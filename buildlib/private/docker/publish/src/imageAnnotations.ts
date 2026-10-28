import type { WorkspaceStatus } from "../../../js-lib/src/loadWorkspaceStatus.js";
import type { BaseProvenanceInfo } from "./loadBaseProvenance.js";

const forStatus = (status: WorkspaceStatus) => {
  const version = status.tag === "latest" ? "" : status.tag;

  return [
    // OCI specified annotations
    // https://github.com/opencontainers/image-spec/blob/main/annotations.md#pre-defined-annotation-keys
    //
    // Explicitly reset annotations to make sure they are not inherited from the base image.

    ["org.opencontainers.image.created", status.buildTime.toISOString()],
    ["org.opencontainers.image.authors", ""],
    ["org.opencontainers.image.url", status.url],
    ["org.opencontainers.image.documentation", ""],
    ["org.opencontainers.image.source", status.source],
    ["org.opencontainers.image.version", version],
    ["org.opencontainers.image.revision", status.commit],
    ["org.opencontainers.image.vendor", ""],
    ["org.opencontainers.image.licenses", ""],
    // org.opencontainers.image.ref.name: don't set, only for multi-arch.
    ["org.opencontainers.image.title", ""],
    ["org.opencontainers.image.description", ""],

    // org.opencontainers.image.base.{digest|name} set in forBase.

    // Our custom annotations
    ["ch.datahouse.dev.build-host", status.buildHost],
    ["ch.datahouse.dev.build-user", status.buildUser],
  ];
};

const resetStatus = [
  ["org.opencontainers.image.created", ""],
  ["org.opencontainers.image.authors", ""],
  ["org.opencontainers.image.url", ""],
  ["org.opencontainers.image.documentation", ""],
  ["org.opencontainers.image.source", ""],
  ["org.opencontainers.image.version", ""],
  ["org.opencontainers.image.revision", ""],
  ["org.opencontainers.image.vendor", ""],
  ["org.opencontainers.image.licenses", ""],
  // org.opencontainers.image.ref.name: don't set, only for multi-arch.
  ["org.opencontainers.image.title", ""],
  ["org.opencontainers.image.description", ""],
];

const forBase = ({ registry, repository, digest }: BaseProvenanceInfo) => [
  ["org.opencontainers.image.base.digest", digest],
  ["org.opencontainers.image.base.name", `${registry}/${repository}`],
];

const build = (baseInfo?: BaseProvenanceInfo, status?: WorkspaceStatus) => {
  if (!baseInfo) return status ? forStatus(status) : [];

  if (status) return [...forStatus(status), ...forBase(baseInfo)];

  // If we have a base but no status, reset other OCI annotations so they are not inherited from the base.
  return [...resetStatus, ...forBase(baseInfo)];
};

export const imageAnnotations = (
  baseInfo?: BaseProvenanceInfo,
  status?: WorkspaceStatus,
): string => {
  const annots = build(baseInfo, status);
  return annots.map(([k, v]) => `${k}=${v}\n`).join("");
};
