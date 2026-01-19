"""Constants for supported platforms related to docker compose"""

OS_TO_CONSTRAINT = {
    "darwin": "@platforms//os:macos",
    "linux": "@platforms//os:linux",
    "windows": "@platforms//os:windows",
}

ARCH_TO_CONSTRAINT = {
    "aarch64": "@platforms//cpu:arm64",
    "x86_64": "@platforms//cpu:x86_64",
}
