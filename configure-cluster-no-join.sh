#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e
# Print each command to the console before executing it.
set -x

# Script parameter from the ARM template
# $1: The username to be added to the docker group (e.g., 'student')
AZURE_USER=$1


# --- 1. System Setup & Docker Installation ---

echo "Starting system setup and Docker installation..."

# Update package lists and install prerequisites
sudo apt-get update
sudo apt-get install -y ca-certificates curl

# Add Docker's official GPG key
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the Docker repository to Apt sources
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# Install the latest version of Docker Engine
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add the student user to the 'docker' group to run docker commands without sudo
if id -u "${AZURE_USER}" >/dev/null 2>&1; then
    sudo usermod -aG docker ${AZURE_USER}
    echo "User '${AZURE_USER}' has been added to the docker group."
    echo "Note: The user may need to log out and log back in for group changes to take effect."
else
    echo "Warning: User '${AZURE_USER}' was not found. Skipping adding user to the docker group."
fi


echo "--- INSTALLATION COMPLETE ---"