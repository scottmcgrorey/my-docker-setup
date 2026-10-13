#!/bin/bash
set -e

# Points to the base directory where your stack folders live
BASE_DIR="/dockerfiles"

# Shared external networks used across multiple compose files
NETWORKS=("proxy_net" "media_net" "automation_net")

# Order of deployment: Infrastructure/Networking -> Databases/Base Services -> Applications
STACKS=("networking" "infra" "arr-management" "arr-library" "data-cloud" "automation" )

echo "--> Synchronizing External Networks..."
for net in "${NETWORKS[@]}"; do
    if docker network create "$net" 2>/dev/null; then
        echo "    Created network: $net"
    else
        echo "    Network $net ready."
    fi
done

echo "--- Starting Modernized Media Stack ---"

for STACK in "${STACKS[@]}"; do
    STACK_DIR="$BASE_DIR/$STACK"

    if [ -f "$STACK_DIR/compose.yml" ]; then
        FILE="$STACK_DIR/compose.yml"
    elif [ -f "$STACK_DIR/docker-compose.yml" ]; then
        FILE="$STACK_DIR/docker-compose.yml"
    else
        echo " [!] Warning: No compose file found in $STACK_DIR. Skipping..."
        continue
    fi

    echo "--> Deploying $STACK..."
    docker compose -f "$FILE" up -d --remove-orphans

    # Critical Wait: Gluetun must be healthy before proceeding
    if [ "$STACK" == "networking" ]; then
        echo "    [WAIT] Verifying VPN Health..."
        until [ "$(docker inspect -f '{{.State.Health.Status}}' gluetun 2>/dev/null)" == "healthy" ]; do
            printf "."
            sleep 2
        done
        echo -e "\n    [OK] VPN Tunnel established."
    fi

    # Database Initialization Buffer
    if [ "$STACK" == "infra" ]; then
        echo "    [WAIT] Allowing Databases to initialize..."
        sleep 5
    fi
done

echo "--- All stacks processed! ---"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Networks}}"
