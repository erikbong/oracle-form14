#!/bin/bash
################################################################################
# Oracle Forms & Reports 14c - Container Restore Script
#
# This script restores a backed up Oracle Forms & Reports container
################################################################################

BACKUP_DIR="./backups"
TIMESTAMP=$1

if [ -z "$TIMESTAMP" ]; then
    echo "Usage: $0 <timestamp>"
    echo ""
    echo "Available backups:"
    ls -1 "$BACKUP_DIR"/oracle-forms-14c-*.tar.gz 2>/dev/null | sed 's/.*oracle-forms-14c-\(.*\)\.tar\.gz/  \1/'
    exit 1
fi

IMAGE_FILE="${BACKUP_DIR}/oracle-forms-14c-${TIMESTAMP}.tar.gz"
VOLUME_FILE="${BACKUP_DIR}/oracle-volumes-${TIMESTAMP}.tar.gz"

if [ ! -f "$IMAGE_FILE" ]; then
    echo "ERROR: Backup file not found: $IMAGE_FILE"
    exit 1
fi

echo "================================================================================"
echo "  Oracle Forms & Reports 14c - Container Restore"
echo "================================================================================"
echo ""

echo "Step 1/3: Loading Docker image..."
gunzip -c "$IMAGE_FILE" | docker load
echo "✓ Image loaded"
echo ""

if [ -f "$VOLUME_FILE" ]; then
    echo "Step 2/3: Restoring volume data..."
    echo "WARNING: This will overwrite existing ./Oracle directory!"
    read -p "Continue? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        tar -xzf "$VOLUME_FILE"
        echo "✓ Volumes restored"
    else
        echo "Skipped volume restore"
    fi
else
    echo "Step 2/3: No volume backup found, skipping..."
fi
echo ""

echo "Step 3/3: Ready to start container..."
echo "To start the container, run:"
echo "  docker-compose -f docker-compose.manual.yml up -d"
echo ""
echo "================================================================================"
echo "Restore completed!"
echo "================================================================================"
echo ""
