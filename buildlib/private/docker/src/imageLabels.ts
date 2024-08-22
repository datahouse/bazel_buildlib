export interface Status {
  revision: string;
  source: string;
  url: string;
  tag: string;
  buildHost: string;
  buildUser: string;
  buildTimestamp: number;
}

export const labelsForStatus = (status: Status): string => {
  const buildTime = new Date(status.buildTimestamp * 1000).toISOString();

  let res =
    `org.opencontainers.image.revision=${status.revision}\n` +
    `org.opencontainers.image.source=${status.source}\n` +
    `org.opencontainers.image.url=${status.url}\n` +
    `org.opencontainers.image.created=${buildTime}\n` +
    `ch.datahouse.dev.build-host=${status.buildHost}\n` +
    `ch.datahouse.dev.build-user=${status.buildUser}\n`;

  if (status.tag !== "latest") {
    res += `org.opencontainers.image.version=${status.tag}\n`;
  }

  return res;
};
