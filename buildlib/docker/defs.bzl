"""Docker and docker compose related rules."""

load("//private/docker:build_dockerfile.bzl", _build_dockerfile = "build_dockerfile")
load("//private/docker:compose.bzl", _docker_compose = "docker_compose")
load("//private/docker:dc_service_reference.bzl", _dc_service_reference = "dc_service_reference")
load("//private/docker:dh_docker_images_push.bzl", _dh_docker_images_push = "dh_docker_images_push")

docker_compose = _docker_compose
dc_service_reference = _dc_service_reference
dh_docker_images_push = _dh_docker_images_push
build_dockerfile = _build_dockerfile
