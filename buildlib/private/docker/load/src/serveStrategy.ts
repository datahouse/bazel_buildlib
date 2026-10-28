import { platform } from "node:process";

import dgram from "node:dgram";

import {
  dockerHost as dockerHostStr,
  allowNonLocalhostBind,
} from "./bazelVars.js";

// Strategy to serve images (to a dockerd).
export interface Strategy {
  bindAddress: string; // where zot listens
  pullAddress: string; // what dockerd connects to
}

// dockerd runs on the same host as we do.
//
// Binding and pulling from localhost will do.
// (`localhost` is also an insecure registry by default, so this is config-free).
const localDockerStrategy: Strategy = {
  bindAddress: "localhost",
  pullAddress: "localhost",
};

// If we use Docker Desktop (or a Podman machine) the actual host
// system (not the VM dockerd runs in) is reachable via host.docker.internal:
// * https://docs.docker.com/desktop/features/networking/networking-how-tos/#connect-a-container-to-a-service-on-the-host
// * https://docs.podman.io/en/v6.1.4/markdown/podman-run.1.html#options
//
// We bind to localhost, but pull from that special address.
//
// Note: this requires additional insecure-registries daemon config.
const dockerInVMStrategy: Strategy = {
  bindAddress: "localhost",
  pullAddress: "host.docker.internal",
};

// Helpers for remote strategy.

interface DockerHost {
  host: string;
  port: number;
}

// Returns the remote docker host if set.
const remoteDockerHost = (): DockerHost | null => {
  const url = new URL(dockerHostStr);

  switch (url.protocol) {
    case "unix:":
      return null; // local dockerd
    case "tcp:":
      return { host: url.hostname, port: Number(url.port) };
    default:
      throw new Error(`unsupported DOCKER_HOST: ${url.toString()}`);
  }
};

const getOutboundAddress = ({ host, port }: DockerHost): Promise<string> =>
  new Promise((resolve, reject) => {
    // Abuse dgram socket for a route call.
    // We connect the socket, but never use it to send anything.
    // We just use it to get the outbound address.

    const socket = dgram.createSocket("udp4"); // v4 only for simplicity.
    socket.once("error", (err) => {
      socket.close();
      reject(err);
    });
    socket.connect(port, host, () => {
      const { address } = socket.address();
      socket.close();
      resolve(address);
    });
  });

const remoteDockerStrategy = async (
  dockerHost: DockerHost,
): Promise<Strategy> => {
  // Docker is running remotely.
  //
  // Bind to the outbound address we'd use to reach the docker host.
  // In any somewhat reasonable network setup, this will find the back route if it exists.
  //
  // However, it is potentially insecure (the bind address might very well be
  // in the public internet).
  // Therefore, we require an explicit "OK" from the environment to do this and fail otherwise.

  const address = await getOutboundAddress(dockerHost);

  if (allowNonLocalhostBind)
    return { bindAddress: address, pullAddress: address };

  const msg = `Refusing to bind docker registry to ${address}.

Cannot determine whether it is secure to do so. If you believe this is in error, set

  --repo_env=DH_BUILDLIB_PERMIT_NON_LOCALHOST_BIND

to your bazel invocation.`;

  throw new Error(msg);
};

export const pickStrategy = async (): Promise<Strategy> => {
  if (platform !== "linux") {
    // If we are not on linux, Docker in VM is the only strategy that may work.
    //
    // We are in one of the following cases:
    // - dockerd in VM: this is the main use case.
    // - dind in dockerd in VM: will also work with this strategy.
    // - remote docker: not supported.
    return dockerInVMStrategy;
  }

  const dockerHost = remoteDockerHost();

  if (dockerHost === null) {
    return localDockerStrategy; // dockerd is local.
  }

  return remoteDockerStrategy(dockerHost);
};
