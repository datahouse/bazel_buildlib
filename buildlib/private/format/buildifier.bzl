"""Buildifier download constants."""

BASE_URL = "https://github.com/bazelbuild/buildtools/releases/download/v7.1.2/buildifier-"

# Get the sha:
# curl -L <url> | sha256sum | xxd --reverse --plain | base64
PLATFORMS = {
    "darwin-amd64": struct(
        integrity = "sha256-aHxJwxj7ZVlwz3Fu7Tx7/Jyu6k8pMaL9Nlk8RY3gxTc=",
        exec_compatible_with = [
            "@platforms//os:macos",
            "@platforms//cpu:x86_64",
        ],
    ),
    "darwin-arm64": struct(
        integrity = "sha256-0JCbZFSWYI/W38Z/ldnTsB2Qc217jI7EHoAssLfOrnw=",
        exec_compatible_with = [
            "@platforms//os:macos",
            "@platforms//cpu:arm64",
        ],
    ),
    "linux-amd64": struct(
        integrity = "sha256-KChf5+Oe0j3Bo6Ul383MvJbAA0/x1Cd5BdJnKnGzjxM=",
        exec_compatible_with = [
            "@platforms//os:linux",
            "@platforms//cpu:x86_64",
        ],
    ),
    "linux-arm64": struct(
        integrity = "sha256-wipE7uN7iScWfubuZ1czA/TjEXHn7DqOoCGmpmAEBDc=",
        exec_compatible_with = [
            "@platforms//os:linux",
            "@platforms//cpu:arm64",
        ],
    ),
}
