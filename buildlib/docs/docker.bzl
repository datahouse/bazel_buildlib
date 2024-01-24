"""Docker and docker compose related rules."""

load("//private/docker:compose.bzl", _docker_compose = "docker_compose")
load("//private/docker:dc_service_reference.bzl", _dc_service_reference = "dc_service_reference")
load("//private/docker:dh_docker_images_push.bzl", _dh_docker_images_push = "dh_docker_images_push")
load("//private/docker:image_for_ts_test.bzl", _docker_image_for_ts_test = "docker_image_for_ts_test")
load("//private/docker:node_binary_image.bzl", _node_binary_image = "node_binary_image")
load("//repositories:docker_containers.bzl", _container_pull = "container_pull")

docker_compose = _docker_compose
dc_service_reference = _dc_service_reference
dh_docker_images_push = _dh_docker_images_push
docker_image_for_ts_test = _docker_image_for_ts_test
node_binary_image = _node_binary_image
container_pull = _container_pull
