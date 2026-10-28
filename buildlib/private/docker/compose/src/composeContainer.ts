import type Docker from "dockerode";

export interface DcServiceReference {
  project: string;
  service: string;
  index: number;
  port: number;
  composeLabel: string;
}

export type ComposeContainerResult =
  { type: "ok"; address: string } | { type: "err"; message: string };

export const getComposeContainerAddress = async (
  docker: Docker,
  { project, service, index, port, composeLabel }: DcServiceReference,
): Promise<ComposeContainerResult> => {
  const containers = await docker.listContainers({
    filters: {
      // For label spec see:
      // https://docs.docker.com/reference/compose-file/services/#labels
      label: [
        `com.docker.compose.project=${project}`,
        `com.docker.compose.service=${service}`,
        // container-number is not part of the documented compose label spec,
        // but is set by docker compose in practice.
        `com.docker.compose.container-number=${index}`,
      ],
    },
  });

  if (containers.length > 1) {
    return {
      type: "err",
      message: `Expected at most 1 container for ${project}-${service}-${index}, found ${containers.length}`,
    };
  }

  if (containers.length < 1) {
    return {
      type: "err",
      message: `No running container found. To start the container:\nbazelisk run ${composeLabel} -- up -d ${service}`,
    };
  }

  const container = containers[0];
  const ip = Object.values(container.NetworkSettings.Networks)[0]?.IPAddress;
  if (!ip) {
    return {
      type: "err",
      message: `Container ${container.Id} has no IP addresses.`,
    };
  }

  return { type: "ok", address: `${ip}:${port}` };
};
