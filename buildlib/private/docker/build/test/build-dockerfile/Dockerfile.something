ARG BASE_IMAGE
FROM ${BASE_IMAGE} as image

FROM image as builder

WORKDIR /build

# Just run a command to check it works.
RUN node -v > node_version.txt

FROM image

COPY --from=builder /build/node_version.txt /node_version.txt
