#! /bin/sh

if ! docker compose --project-name {{COMPOSE_PROJECT}} --file {{COMPOSE_FILE}} port --index {{SERVICE_INDEX}} {{SERVICE_NAME}} {{SERVICE_PORT}}; then
    echo "Failed to retrieve docker service reference. Is the container running?" >&2
    echo "To start the container:" >&2
    echo "bazelisk run {{COMPOSE_LABEL}} -- up -d {{SERVICE_NAME}}" >&2
    exit 1
fi
