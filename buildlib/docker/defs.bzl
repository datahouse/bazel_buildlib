"""Docker and docker compose related rules."""

load("//private/docker:build_dockerfile.bzl", _build_dockerfile = "build_dockerfile")
load("//private/docker:dc_service_reference.bzl", _dc_service_reference = "dc_service_reference")
load("//private/docker:dh_docker_images_push.bzl", _dh_docker_images_push = "dh_docker_images_push")
load("//private/docker:extract_from_image.bzl", _extract_from_image = "extract_from_image")
load("//private/docker/compose:compose.bzl", _docker_compose = "docker_compose")

docker_compose = _docker_compose
dc_service_reference = _dc_service_reference
dh_docker_images_push = _dh_docker_images_push
build_dockerfile = _build_dockerfile
extract_from_image = _extract_from_image
