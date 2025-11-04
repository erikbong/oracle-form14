#!/bin/bash
################################################################################
# Oracle Forms & Reports 14c - Container Backup Script
#
# This script creates a backup of your configured Oracle Forms & Reports
# container including all state and configuration.
################################################################################

CONTAINER_NAME="oracle-forms-manual-install"
BACKUP_DIR="./backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
IMAGE_NAME="oracle-forms-14c-configured"

echo "================================================================================"
echo "  Oracle Forms & Reports 14c - Container Backup"
echo "================================================================================"
echo ""

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Check if container exists
if ! docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "ERROR: Container ${CONTAINER_NAME} not found!"
    exit 1
fi

echo "Step 1/3: Creating Docker image snapshot..."
docker commit "$CONTAINER_NAME" "${IMAGE_NAME}:${TIMESTAMP}"
docker tag "${IMAGE_NAME}:${TIMESTAMP}" "${IMAGE_NAME}:latest"
echo "✓ Image created: ${IMAGE_NAME}:${TIMESTAMP}"
echo ""

echo "Step 2/3: Exporting image to tar file..."
docker save "${IMAGE_NAME}:${TIMESTAMP}" | gzip > "${BACKUP_DIR}/oracle-forms-14c-${TIMESTAMP}.tar.gz"
echo "✓ Image exported to: ${BACKUP_DIR}/oracle-forms-14c-${TIMESTAMP}.tar.gz"
echo ""

echo "Step 3/3: Creating volume backup..."
tar -czf "${BACKUP_DIR}/oracle-volumes-${TIMESTAMP}.tar.gz" ./Oracle
echo "✓ Volumes backed up to: ${BACKUP_DIR}/oracle-volumes-${TIMESTAMP}.tar.gz"
echo ""

echo "================================================================================"
echo "Backup completed successfully!"
echo "================================================================================"
echo ""
echo "Backup files created:"
echo "  - Container image: ${BACKUP_DIR}/oracle-forms-14c-${TIMESTAMP}.tar.gz"
echo "  - Volume data:     ${BACKUP_DIR}/oracle-volumes-${TIMESTAMP}.tar.gz"
echo ""
echo "Total backup size:"
du -sh "${BACKUP_DIR}/oracle-forms-14c-${TIMESTAMP}.tar.gz" "${BACKUP_DIR}/oracle-volumes-${TIMESTAMP}.tar.gz"
echo ""
echo "To restore this backup, use: ./restore-container.sh ${TIMESTAMP}"
echo ""
