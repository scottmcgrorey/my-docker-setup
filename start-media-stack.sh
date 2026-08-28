#!/bin/bash
# Points to the base directory where your stack folders live
BASE_DIR="/dockerfiles" 

# REORDERED: Networking & Infra first so VPN/Proxy/DBs are ready for the Apps
STACKS=("networking" "infra" "arr-management" "arr-library" "data-cloud" "automation")

echo "--> Synchronizing External Networks..."
# Only create the networks marked as 'external' in your compose files
for net in proxy_net media_net; do
    docker network create $net 2>/dev/null || echo "    $net ready."
done

echo "--- Starting Modernized Media Stack ---"

for STACK in "${STACKS[@]}"; do
    STACK_DIR="$BASE_DIR/$STACK"
    
    if [ -f "$STACK_DIR/compose.yml" ]; then
        FILE="$STACK_DIR/compose.yml"
    elif [ -f "$STACK_DIR/docker-compose.yml" ]; then
        FILE="$STACK_DIR/docker-compose.yml"
    else
        echo " [!] Error: No compose file found in $STACK_DIR"
        continue
    fi

    echo "--> Deploying $STACK..."
    # Using --remove-orphans ensures old versions of renamed containers are cleaned up
    docker compose -f "$FILE" up -d --remove-orphans
    
    # Critical Wait: Gluetun must be healthy for qBittorrent to start
    if [ "$STACK" == "networking" ]; then
        echo "    [WAIT] Verifying VPN Health..."
        until [ "$(docker inspect -f '{{.State.Health.Status}}' gluetun 2>/dev/null)" == "healthy" ]; do
            printf "."
            sleep 2
        done
        echo -e "\n    [OK] VPN Tunnel established."
    fi

    # Optional Wait: Give Databases a moment to initialize in the Infra stack
    if [ "$STACK" == "infra" ]; then
        echo "    [WAIT] Allowing Databases to initialize..."
        sleep 5
    fi
done

echo "--- All stacks processed! ---"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Networks}}"
