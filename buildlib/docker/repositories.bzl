"""Docker repository rules.

You can only use these rules in the WORKSPACE file.
"""

load("//repositories:docker_containers.bzl", _container_pull = "container_pull")

container_pull = _container_pull
