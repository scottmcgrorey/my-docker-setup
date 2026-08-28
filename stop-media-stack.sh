#!/bin/bash

# Define the root directory
DOCKER_ROOT="/etc/dockerfiles"

# Define the stacks in REVERSE order of dependency
# 1. Apps (Arrs/Automation) go down first
# 2. Infra (Databases/Dashboards)
# 3. Networking (VPN/Proxy) goes down last
STACKS=("arr-library" "arr-management" "automation" "infra" "networking")

echo "--- Stopping Media Stack ---"

for STACK in "${STACKS[@]}"; do
    if [ -d "$DOCKER_ROOT/$STACK" ]; then
        echo "--> Stopping $STACK..."
        cd "$DOCKER_ROOT/$STACK" && sudo docker compose down
    else
        echo " [!] Warning: Directory $DOCKER_ROOT/$STACK not found. Skipping."
    fi
done

echo "--- All stacks have been stopped! ---"
# Prune dangling images to save space
sudo docker image prune -f

# Prune unused networks (only those not in use)
sudo docker network prune -f

echo "--- Cleanup complete! ---"
