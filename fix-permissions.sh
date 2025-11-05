#!/bin/bash
################################################################################
# Oracle Forms & Reports 14c - Permission Fix Script
#
# This script fixes all file and directory permissions for the Oracle folder
# after extracting from a tar.gz backup.
#
# Usage: ./fix-permissions.sh
#
# What it does:
# 1. Stops all containers
# 2. Creates required directories
# 3. Sets correct ownership (oracle user: UID 54321, GID 54321)
# 4. Sets all permissions to 755 (simple and comprehensive)
# 5. Cleans up VNC lock files
# 6. Starts services
################################################################################

set -e  # Exit on any error

echo "=============================================================================="
echo "  Oracle Forms & Reports 14c - Permission Fix"
echo "=============================================================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ] && ! sudo -n true 2>/dev/null; then
    echo -e "${RED}Error: This script requires sudo privileges${NC}"
    echo "Please run: sudo ./fix-permissions.sh"
    exit 1
fi

# Check if Oracle directory exists
if [ ! -d "./Oracle" ]; then
    echo -e "${RED}Error: ./Oracle directory not found!${NC}"
    echo "Please extract your Oracle backup first."
    exit 1
fi

echo -e "${BLUE}[1/6]${NC} Stopping containers..."
docker-compose down 2>/dev/null || true

echo -e "${BLUE}[2/6]${NC} Creating required directories..."
mkdir -p ./logs
mkdir -p ./forms_source
mkdir -p ./reports_source
mkdir -p ./reports_temp
mkdir -p ./config/forms
mkdir -p ./config/reports
mkdir -p ./config/tnsnames

echo -e "${BLUE}[3/6]${NC} Setting ownership to oracle user (UID:54321, GID:54321)..."
sudo chown -R 54321:54321 ./Oracle/
sudo chown -R 54321:54321 ./logs/
sudo chown -R 54321:54321 ./forms_source/
sudo chown -R 54321:54321 ./reports_source/
sudo chown -R 54321:54321 ./reports_temp/
sudo chown -R 54321:54321 ./config/

echo -e "${BLUE}[4/6]${NC} Setting all Oracle files and directories to 755..."
sudo chmod -R 755 ./Oracle/
echo "  ✓ All Oracle permissions fixed"

echo -e "${BLUE}[5/6]${NC} Setting permissions for project directories..."
sudo chmod -R 755 ./logs/
sudo chmod -R 755 ./forms_source/
sudo chmod -R 755 ./reports_source/
sudo chmod -R 755 ./reports_temp/
sudo chmod -R 755 ./config/
echo "  ✓ Project directory permissions fixed"

echo -e "${BLUE}[6/6]${NC} Cleaning up VNC lock files..."
sudo rm -f ./Oracle/.X*-lock 2>/dev/null || true
sudo rm -rf ./Oracle/.X11-unix 2>/dev/null || true
sudo find ./Oracle -name ".X*-lock" -delete 2>/dev/null || true

echo ""
echo -e "${GREEN}=============================================================================="
echo "  Permission Fix Complete!"
echo "==============================================================================${NC}"
echo ""
echo "Summary:"
echo "  ✓ Ownership set to oracle user (UID:54321)"
echo "  ✓ All Oracle permissions set to 755"
echo "  ✓ Project directory permissions set to 755"
echo "  ✓ VNC lock files cleaned"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Start services: docker-compose up -d"
echo "  2. Monitor logs: docker logs -f oracle-forms-14c"
echo "  3. Wait 5-8 minutes for all services to start"
echo ""
echo -e "${BLUE}Press Enter to start services now, or Ctrl+C to exit...${NC}"
read -r

echo ""
echo "Starting services..."
docker-compose up -d

echo ""
echo "Waiting 10 seconds for initialization..."
sleep 10

echo ""
echo -e "${GREEN}Services started! Showing logs (Ctrl+C to exit)...${NC}"
echo ""
docker logs -f oracle-forms-14c
