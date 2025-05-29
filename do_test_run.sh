#!/usr/bin/env bash

# Stop at first error
set -e

# --- Setup Variables ---
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
DOCKER_IMAGE_TAG="${DOCKER_IMAGE_TAG:-lunascore-open-development-phase}"

# If user passes a tag as an argument, override
if [ "$#" -eq 1 ]; then
    DOCKER_IMAGE_TAG="$1"
fi

DOCKER_NOOP_VOLUME="${DOCKER_IMAGE_TAG}-volume"

INPUT_DIR="${SCRIPT_DIR}/input"
OUTPUT_DIR="${SCRIPT_DIR}/output"

# --- Build Docker Image ---
echo '=+= build the container'
source "${SCRIPT_DIR}/do_build.sh" "$DOCKER_IMAGE_TAG"

# --- Ensure Clean Output Directory ---
echo "=+= Cleaning up any earlier output"
if [ -d "$OUTPUT_DIR" ]; then
  # Ensure permissions are setup correctly
  # This allows for the Docker user to write to this location
  rm -rf "${OUTPUT_DIR}"/*
  chmod -f o+rwx "$OUTPUT_DIR"
else
  mkdir -m o+rwx "$OUTPUT_DIR"
fi


# --- Function to Restore Output Permissions After Docker Run ---
cleanup() {
    echo '=+= Cleaning permissions ...'
    docker run --rm \
      --quiet \
      --volume "$OUTPUT_DIR":/output \
      --entrypoint /bin/sh \
      "$DOCKER_IMAGE_TAG" \
      -c "chmod -R -f o+rwX /output/* || true"
}
trap cleanup EXIT

# --- Run the Inference Docker Container ---
echo '=+= Doing a forward pass'

# Create a dummy /tmp volume (required for Grand Challenge compatibility)
docker volume create "$DOCKER_NOOP_VOLUME" > /dev/null

# Check if GPU is available (skip --gpus for non-GPU environments like CI)
GPU_OPTION="--gpus all"
if ! docker info | grep -q "Runtimes: nvidia"; then
    echo 'GPU runtime not available. Running without GPU support.'
    GPU_OPTION=""
fi

docker run --rm \
    --platform=linux/amd64 \
    --network none \
    $GPU_OPTION \
    --volume "$INPUT_DIR":/input:ro \
    --volume "$OUTPUT_DIR":/output \
    --volume "$DOCKER_NOOP_VOLUME":/tmp \
    "$DOCKER_IMAGE_TAG"

docker volume rm "$DOCKER_NOOP_VOLUME" > /dev/null

# --- Fix Output Ownership for Host ---
docker run --rm \
    --quiet \
    --env HOST_UID="$(id -u)" \
    --env HOST_GID="$(id -g)" \
    --volume "$OUTPUT_DIR":/output \
    alpine:latest \
    /bin/sh -c 'chown -R ${HOST_UID}:${HOST_GID} /output'

echo "=+= Wrote results to ${OUTPUT_DIR}"
echo "=+= Save this image for uploading via ./do_save.sh \"${DOCKER_IMAGE_TAG}\""
