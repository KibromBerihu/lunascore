'''
#!/usr/bin/env bash

# Stop at first error
set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
DOCKER_IMAGE_TAG="lunascore-open-development-phase"


# Check if an argument is provided
if [ "$#" -eq 1 ]; then
    DOCKER_IMAGE_TAG="$1"
fi

# Note: the build-arg is JUST for the workshop
docker build "$SCRIPT_DIR" \
  --platform=linux/amd64 \
  --tag "$DOCKER_IMAGE_TAG" 2>&1

'''


#!/usr/bin/env bash

# Stop on first error
set -e

# Get directory of this script
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Default image tag
DOCKER_IMAGE_TAG="lunascore-open-development-phase"

# Use the first CLI argument as the image tag, if provided
if [ "$#" -eq 1 ]; then
    DOCKER_IMAGE_TAG="$1"
fi

# Optional: Log which image tag we're using
echo "Building Docker image with tag: $DOCKER_IMAGE_TAG"
echo "Context: $SCRIPT_DIR"

# Build the image
docker build "$SCRIPT_DIR" \
  --platform=linux/amd64 \
  --tag "$DOCKER_IMAGE_TAG"

echo "Docker image '$DOCKER_IMAGE_TAG' built successfully."
