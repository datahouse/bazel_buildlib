"""Public Datahouse buildlib rules/macros.

See the examples/ project for usage or the definitions for documentation.
"""

load("//private/bazelrc:bazelrc.bzl", _bazelrc = "bazelrc")
load("//private/docker:compose.bzl", _docker_compose = "docker_compose")
load("//private/docker:dc_service_reference.bzl", _dc_service_reference = "dc_service_reference")
load("//private/docker:dh_docker_images_push.bzl", _dh_docker_images_push = "dh_docker_images_push")
load("//private/docker:image_for_ts_test.bzl", _docker_image_for_ts_test = "docker_image_for_ts_test")
load("//private/docker:node_binary_image.bzl", _node_binary_image = "node_binary_image")
load("//private/gql:client_codegen.bzl", _gql_client_codegen = "gql_client_codegen")
load("//private/gql:schema.bzl", _gql_schema = "gql_schema")
load("//private/hacks:transpile_esm_to_cjs.bzl", _transpile_esm_to_cjs = "transpile_esm_to_cjs")
load("//private/prisma:cli_image.bzl", _prisma_cli_image = "prisma_cli_image")
load("//private/prisma:dev.bzl", _prisma_dev = "prisma_dev")
load("//private/prisma:generate.bzl", _prisma_generate = "prisma_generate", _prisma_providers = "prisma_providers")
load("//private/prisma:schema.bzl", _prisma_schema = "prisma_schema")
load("//private/react_app:react_app.bzl", _react_app = "react_app")
load("//private/renovate:renovate.bzl", _renovate_config = "renovate_config")
load("//private/tar:tar.bzl", _mtree_replace_prefix = "mtree_replace_prefix", _mtree_spec = "mtree_spec", _tar_auto_mtree = "tar_auto_mtree")
load("//private/ts:config.bzl", _tsconfig_base = "tsconfig_base")
load("//private/ts:eslintrc.bzl", _eslintrc = "eslintrc")
load("//private/ts:js_binary.bzl", _js_binary = "js_binary")
load("//private/ts:library.bzl", _ts_default_srcs = "ts_default_srcs", _ts_library = "ts_library")
load("//private/ts:pnpm_lock_test.bzl", _pnpm_lock_test = "pnpm_lock_test")
load("//private/ts:setup.bzl", _ts_setup = "ts_setup")
load("//private/ts:test.bzl", _ts_test = "ts_test")

ts_library = _ts_library
ts_test = _ts_test
ts_default_srcs = _ts_default_srcs
js_binary = _js_binary
ts_setup = _ts_setup
pnpm_lock_test = _pnpm_lock_test
docker_compose = _docker_compose
dc_service_reference = _dc_service_reference
dh_docker_images_push = _dh_docker_images_push
docker_image_for_ts_test = _docker_image_for_ts_test
node_binary_image = _node_binary_image
gql_schema = _gql_schema
gql_client_codegen = _gql_client_codegen
renovate_config = _renovate_config
bazelrc = _bazelrc
eslintrc = _eslintrc
tsconfig_base = _tsconfig_base
react_app = _react_app
prisma_schema = _prisma_schema
prisma_generate = _prisma_generate
prisma_providers = _prisma_providers
prisma_cli_image = _prisma_cli_image
prisma_dev = _prisma_dev
mtree_replace_prefix = _mtree_replace_prefix
mtree_spec = _mtree_spec
tar_auto_mtree = _tar_auto_mtree

# Hacks
transpile_esm_to_cjs = _transpile_esm_to_cjs
