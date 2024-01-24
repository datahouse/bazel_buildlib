"""Docker specific providers (dh buildlib private)."""

DockerComposeInfo = provider(
    doc = """Provider for docker compose results (dh buildlib private).""",
    fields = {
        "file": "Generated docker-compose.yml file",
        "project": "The docker compse project name",
    },
)

DcServiceReferenceInfo = provider(
    doc = """Marker provider for docker compose service references (dh buildlib private).""",
    fields = {},
)

HotReloadableInfo = provider(
    doc = """Provider for hot reloadable docker images.""",
    fields = {
        "container_path": "Path inside container where to mount the hot reloadable files.",
        "files": "Depset of files to be hot reloaded (into container_path).",
        "oci_image": "The oci image (directory) to use for hot reload.",
    },
)
