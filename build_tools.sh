#!/bin/bash
# Script to build, tag, and manage the dev-tools Docker image

DEFAULT_CONTAINER_BASE="dev-tools"
CUSTOM_NAME=""

echo "--- Docker Image Naming and Workflow ---"

# Prompt for a custom name
read -p "Enter a unique project/container name (or press Enter to use '$DEFAULT_CONTAINER_BASE'): " CUSTOM_NAME

if [ -z "$CUSTOM_NAME" ]; then
    FINAL_REPO_NAME="$DEFAULT_CONTAINER_BASE"
    echo "Using default repository name: $FINAL_REPO_NAME"
else
    # Simple sanitization: replace spaces/special characters with underscores and lowercase
    SANITIZED_NAME=$(echo "$CUSTOM_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '_')
    FINAL_REPO_NAME="${SANITIZED_NAME}"
    echo "Using custom repository name: $FINAL_REPO_NAME (Sanitized to: ${SANITIZED_NAME})"
fi

# The TAG should ideally be dynamic, but for simplicity, we establish the repo name.
IMAGE_TAG="$FINAL_REPO_NAME:develop"

echo ""
echo "=========================================="
echo "Action Plan:"
echo "1. Docker Image Tag determined: $IMAGE_TAG"
echo "2. To build (using the existing Dockerfile): docker build -t $IMAGE_TAG ."
echo "3. To run with Compose (recommended for local dev):"
# Since we customize the name, the static compose file needs modification or a new one should be used.
# For now, I recommend overriding the image reference in your docker-compose.yml temporarily during this workflow to match. This is an educational step/gotcha check.
echo "   A wrapper must update 'docker-compose.yml' to use '$FINAL_REPO_NAME'."
echo ""

read -p "Do you wish to proceed with the build now? (y/n): " CONFIRM_BUILD
if [[ "$CONFIRM_BUILD" == "y" || "$CONFIRM_BUILD" == "Y" ]]; then
    echo "Starting build process..."
    # Run the actual build command based on the final name. This requires manual execution or integrating this script's logic into Make/CI.
    # For now, we provide a placeholder of the intended action:
    docker build -t $IMAGE_TAG .
    if [ $? -eq 0 ]; then
        echo "✅ Build successful! Your custom-named image is ready."
    else
        echo "❌ Build failed. Check Docker logs for errors."
    fi
else
    echo "Build process skipped. Run 'docker build -t $IMAGE_TAG .' when ready."
fi