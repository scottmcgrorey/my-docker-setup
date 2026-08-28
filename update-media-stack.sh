#!/usr/bin/env bash
set -e

# Define your stack directories in order of dependency
STACKS=(
  "/dockerfiles/infra"
  "/dockerfiles/networking"
  "/dockerfiles/arr-management"
  "/dockerfiles/arr-library"
  "/dockerfiles/automation"
  "/dockerfiles/data-cloud"
)

echo "=================================================="
echo " Starting Rolling Update for All Docker Stacks    "
echo "=================================================="

for STACK in "${STACKS[@]}"; do
  if [ -d "$STACK" ]; then
    echo ""
    echo "--------------------------------------------------"
    echo " Updating Stack: $STACK"
    echo "--------------------------------------------------"
    cd "$STACK"
    
    # 1. Pull latest images for this specific compose file
    docker compose pull
    
    # 2. Re-create ONLY containers with updated images
    docker compose up -d
    
    echo "Done updating $STACK."
  else
    echo "Warning: Directory $STACK not found, skipping."
  fi
done

echo ""
echo "=================================================="
echo " Cleaning Up Unused (Pruned) Images               "
echo "=================================================="
# Removes old dangling image layers left behind by updates
docker image prune -f

echo ""
echo "All stacks updated successfully!"
