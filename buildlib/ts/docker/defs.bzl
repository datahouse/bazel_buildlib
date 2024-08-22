"""Rules for Typescript in/on Docker."""

load("//private/docker:image_for_ts_test.bzl", _docker_image_for_ts_test = "docker_image_for_ts_test")
load("//private/docker:node_binary_image.bzl", _node_binary_image = "node_binary_image")

docker_image_for_ts_test = _docker_image_for_ts_test
node_binary_image = _node_binary_image
