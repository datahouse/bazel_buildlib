"""Docker and docker compose related rules."""

load("//private/docker:compose.bzl", _docker_compose = "docker_compose")
load("//private/docker:dc_service_reference.bzl", _dc_service_reference = "dc_service_reference")
load("//private/docker:dh_docker_images_push.bzl", _dh_docker_images_push = "dh_docker_images_push")
load("//private/docker:node_binary_image.bzl", _node_binary_image = "node_binary_image")
load("//private/docker:pull_info.bzl", _docker_pull_info = "docker_pull_info")

docker_compose = _docker_compose
dc_service_reference = _dc_service_reference
dh_docker_images_push = _dh_docker_images_push
docker_pull_info = _docker_pull_info
node_binary_image = _node_binary_image
