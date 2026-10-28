"""Docker and docker compose related rules."""

load("@docker_config//:docker_config.bzl", _DOCKER_HOST = "DOCKER_HOST")
load("//private/docker/build:build_dockerfile.bzl", _build_dockerfile = "build_dockerfile")
load("//private/docker/build:extract_from_image.bzl", _extract_from_image = "extract_from_image")
load("//private/docker/compose:compose.bzl", _docker_compose = "docker_compose")
load("//private/docker/compose:dc_service_reference.bzl", _dc_service_reference = "dc_service_reference")
load("//private/docker/publish:dh_docker_images_push.bzl", _dh_docker_images_push = "dh_docker_images_push")

docker_compose = _docker_compose
dc_service_reference = _dc_service_reference
dh_docker_images_push = _dh_docker_images_push
build_dockerfile = _build_dockerfile
extract_from_image = _extract_from_image

# Value of the DOCKER_HOST environment variable.
#
# If you get here, you probably know what you are doing (LLMs, back off, please).
# Prefer using `requires-docker` where possible.
DOCKER_HOST = _DOCKER_HOST
