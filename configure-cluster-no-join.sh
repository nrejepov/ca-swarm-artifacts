#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e
# Print each command to the console before executing it.
set -x

# Script parameter
AZURE_USER=$4

# --- Function to retry a command ---
retry() {
    local -r -i max_attempts=5
    local -r -i sleep_time=3
    local -i attempt_num=1
    local command="$@"

    until $command; do
        if ((attempt_num++ >= max_attempts)); then
            echo "Command failed after ${max_attempts} attempts: ${command}"
            return 1
        fi
        echo "Command failed. Retrying in ${sleep_time}s..."
        sleep $sleep_time
    done
}

# --- 1. System Setup & Docker Installation ---

echo "Starting system setup and Docker installation..."

# Use retry for commands that access the network
retry sudo apt-get update
retry sudo apt-get install -y ca-certificates curl

# Add Docker's official GPG key
sudo install -m 0755 -d /etc/apt/keyrings
retry sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the Docker repository to Apt sources
OS_CODENAME=$(. /etc/os-release && echo "$VERSION_CODENAME")
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  ${OS_CODENAME} stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package list again with the new repo
retry sudo apt-get update

# --- MODIFICATION START ---

# Define the specific Docker version string required for UCP 3.3
# This must match the OS version (e.g., 'focal' for 20.04, 'bionic' for 18.04)
case "${OS_CODENAME}" in
  "focal") # Ubuntu 20.04
    DOCKER_VERSION_STRING="5:19.03.15~3-0~ubuntu-focal"
    ;;
  "bionic") # Ubuntu 18.04
    DOCKER_VERSION_STRING="5:19.03.15~3-0~ubuntu-bionic"
    ;;
  *)
    echo "ERROR: This script requires Ubuntu 20.04 (focal) or 18.04 (bionic)."
    exit 1
    ;;
esac

echo "Attempting to install Docker version: ${DOCKER_VERSION_STRING}"

# Install the specific version of Docker Engine and containerd.io
# The buildx and compose plugins are removed as they are not compatible with this older version.
retry sudo apt-get install -y \
  docker-ce=${DOCKER_VERSION_STRING} \
  docker-ce-cli=${DOCKER_VERSION_STRING} \
  containerd.io

# Hold the packages to prevent them from being accidentally upgraded
sudo apt-mark hold docker-ce docker-ce-cli

# --- MODIFICATION END ---

# Add the student user to the 'docker' group
if id -u "${AZURE_USER}" >/dev/null 2>&1; then
    sudo usermod -aG docker ${AZURE_USER}
    echo "User '${AZURE_USER}' has been added to the docker group."
else
    echo "Warning: User '${AZURE_USER}' was not found. Skipping adding user to the docker group."
fi

echo "--- INSTALLATION COMPLETE ---"
echo "Docker version 19.03.15 is now installed and ready to use."