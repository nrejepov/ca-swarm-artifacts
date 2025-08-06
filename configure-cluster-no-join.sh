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
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package list again with the new repo
retry sudo apt-get update

# Install Docker
retry sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add the student user to the 'docker' group
if id -u "${AZURE_USER}" >/dev/null 2>&1; then
    sudo usermod -aG docker ${AZURE_USER}
    echo "User '${AZURE_USER}' has been added to the docker group."
else
    echo "Warning: User '${AZURE_USER}' was not found. Skipping adding user to the docker group."
fi

echo "--- INSTALLATION COMPLETE ---"
echo "Docker is now installed and ready to use."