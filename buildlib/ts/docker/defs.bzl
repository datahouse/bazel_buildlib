"""Rules for Typescript in/on Docker."""

load("//private/docker/build:node_binary_image.bzl", _node_binary_image = "node_binary_image")
load("//private/docker/load:image_for_ts_test.bzl", _docker_image_for_ts_test = "docker_image_for_ts_test")

docker_image_for_ts_test = _docker_image_for_ts_test
node_binary_image = _node_binary_image
