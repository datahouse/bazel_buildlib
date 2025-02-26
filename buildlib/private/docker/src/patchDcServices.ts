export interface ImageInfoWithReference {
  reference: string;
  hotReload?: {
    hostHomePath: string;
    containerPath: string;
  };
}

export type ImageInfos = Map<string, ImageInfoWithReference>;

export interface DockerCompose {
  services: {
    [name: string]: DcService;
  };
}

export interface DcService {
  "bazel-image"?: string;
  image?: string;
  volumes?: string[];
}

type Problem =
  | { problem: "duplicate-image"; serviceName: string }
  | { problem: "missing-label"; serviceName: string; label: string };

const patchService = (
  imageInfos: ImageInfos,
  serviceName: string,
  service: DcService,
): Problem[] => {
  const label = service["bazel-image"];

  if (!label) return []; // not a bazel managed image.

  if (service.image) return [{ problem: "duplicate-image", serviceName }];

  const info = imageInfos.get(label);
  if (!info) return [{ problem: "missing-label", serviceName, label }];

  delete service["bazel-image"];
  service.image = info.reference;

  if (!("hotReload" in info) || !info.hotReload) return [];

  const { hostHomePath, containerPath } = info.hotReload;

  if (!service.volumes) service.volumes = [];

  service.volumes.push(`$HOME/${hostHomePath}:${containerPath}:ro`);

  return [];
};

const fmtProblems = (
  problems: Problem[],
  knownLabels: Iterable<string>,
): string[] => {
  if (problems.length === 0) return [];

  const lines = ["There were problems processing the docker compose file:"];
  let showLabels = false;

  for (const problem of problems) {
    const { serviceName } = problem;

    switch (problem.problem) {
      case "duplicate-image":
        lines.push(`- ${serviceName}: has both bazel-image and image`);
        break;
      case "missing-label":
        showLabels = true;
        lines.push(`- ${serviceName}: unknown label ${problem.label}`);
        break;
      default:
        problem satisfies never;
    }
  }

  if (showLabels) {
    lines.push("");
    lines.push("Labels found in deps:");
    for (const label of knownLabels) {
      lines.push(`- ${label}`);
    }
  }

  return lines;
};

// Replace images that have bazel labels (mutably in dc).
// Returns a list of error lines in case of problems.
// If there are no problems, returns an empty list.
export const patchDcServices = (
  imageInfos: ImageInfos,
  dc: DockerCompose,
): string[] => {
  const problems = Object.entries(dc.services).flatMap(([name, service]) =>
    patchService(imageInfos, name, service),
  );
  return fmtProblems(problems, imageInfos.keys());
};

export const patchDcServicesFake = (dc: DockerCompose) => {
  Object.values(dc.services).forEach((service) => {
    if ("bazel-image" in service) {
      service.image = "fake";
      delete service["bazel-image"];
    }
  });
};
