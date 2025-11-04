#!/bin/bash
################################################################################
# Oracle Forms & Reports 14c Pre-Installation Check Script
#
# This script validates system requirements before Oracle installation
# Run this in VNC terminal before starting installation
################################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Symbols
CHECK="✓"
CROSS="✗"
WARN="⚠"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Oracle Forms & Reports 14c${NC}"
echo -e "${BLUE}Pre-Installation Check${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check counter
ERRORS=0
WARNINGS=0

################################################################################
# Function: Check if command exists
################################################################################
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

################################################################################
# Function: Print check result
################################################################################
print_check() {
    local status=$1
    local message=$2

    if [ "$status" = "pass" ]; then
        echo -e "${GREEN}${CHECK}${NC} ${message}"
    elif [ "$status" = "fail" ]; then
        echo -e "${RED}${CROSS}${NC} ${message}"
        ((ERRORS++))
    elif [ "$status" = "warn" ]; then
        echo -e "${YELLOW}${WARN}${NC} ${message}"
        ((WARNINGS++))
    fi
}

################################################################################
# 1. SYSTEM INFORMATION
################################################################################
echo -e "${BLUE}[1/8] System Information${NC}"
echo "----------------------------------------"

# OS Version
if [ -f /etc/os-release ]; then
    source /etc/os-release
    echo "OS: $PRETTY_NAME"
    if [[ "$ID" == "ol" && "$VERSION_ID" == "8" ]]; then
        print_check "pass" "Oracle Linux 8 detected (recommended)"
    elif [[ "$ID" == "ol" ]]; then
        print_check "pass" "Oracle Linux detected"
    else
        print_check "warn" "Not Oracle Linux (may have compatibility issues)"
    fi
else
    print_check "warn" "Cannot determine OS version"
fi

# Kernel version
KERNEL_VERSION=$(uname -r)
echo "Kernel: $KERNEL_VERSION"

# Architecture
ARCH=$(uname -m)
echo "Architecture: $ARCH"
if [ "$ARCH" = "x86_64" ]; then
    print_check "pass" "64-bit architecture confirmed"
else
    print_check "fail" "Oracle Forms requires 64-bit (x86_64) architecture"
fi

echo ""

################################################################################
# 2. MEMORY CHECK
################################################################################
echo -e "${BLUE}[2/8] Memory Requirements${NC}"
echo "----------------------------------------"

TOTAL_MEM=$(free -m | awk '/^Mem:/{print $2}')
AVAILABLE_MEM=$(free -m | awk '/^Mem:/{print $7}')
SWAP_MEM=$(free -m | awk '/^Swap:/{print $2}')

echo "Total Memory: ${TOTAL_MEM} MB"
echo "Available Memory: ${AVAILABLE_MEM} MB"
echo "Swap Space: ${SWAP_MEM} MB"

TOTAL_AVAILABLE=$((TOTAL_MEM + SWAP_MEM))
echo "Total Available (RAM + Swap): ${TOTAL_AVAILABLE} MB"

# Check minimum requirements
MIN_REQUIRED=8192  # 8 GB
RECOMMENDED=16384  # 16 GB

if [ $TOTAL_AVAILABLE -lt $MIN_REQUIRED ]; then
    print_check "fail" "Insufficient memory: ${TOTAL_AVAILABLE} MB (minimum ${MIN_REQUIRED} MB required)"
elif [ $TOTAL_AVAILABLE -lt $RECOMMENDED ]; then
    print_check "warn" "Memory below recommended: ${TOTAL_AVAILABLE} MB (${RECOMMENDED} MB recommended)"
else
    print_check "pass" "Sufficient memory: ${TOTAL_AVAILABLE} MB"
fi

echo ""

################################################################################
# 3. DISK SPACE CHECK
################################################################################
echo -e "${BLUE}[3/8] Disk Space Requirements${NC}"
echo "----------------------------------------"

# Check /u01 space
U01_SPACE=$(df -BG /u01 | awk 'NR==2 {print $4}' | sed 's/G//')
echo "/u01 available: ${U01_SPACE} GB"

MIN_DISK=15
RECOMMENDED_DISK=30

if [ "$U01_SPACE" -lt "$MIN_DISK" ]; then
    print_check "fail" "Insufficient disk space: ${U01_SPACE} GB (minimum ${MIN_DISK} GB required)"
elif [ "$U01_SPACE" -lt "$RECOMMENDED_DISK" ]; then
    print_check "warn" "Disk space below recommended: ${U01_SPACE} GB (${RECOMMENDED_DISK} GB recommended)"
else
    print_check "pass" "Sufficient disk space: ${U01_SPACE} GB"
fi

# Check /tmp space
TMP_SPACE=$(df -BG /tmp | awk 'NR==2 {print $4}' | sed 's/G//')
echo "/tmp available: ${TMP_SPACE} GB"

MIN_TMP=6
if [ "$TMP_SPACE" -lt "$MIN_TMP" ]; then
    print_check "warn" "Low /tmp space: ${TMP_SPACE} GB (${MIN_TMP} GB recommended)"
else
    print_check "pass" "Sufficient /tmp space: ${TMP_SPACE} GB"
fi

echo ""

################################################################################
# 4. KERNEL PARAMETERS
################################################################################
echo -e "${BLUE}[4/8] Kernel Parameters${NC}"
echo "----------------------------------------"

check_kernel_param() {
    local param=$1
    local min_value=$2
    local current_value=$(sysctl -n $param 2>/dev/null)

    if [ -z "$current_value" ]; then
        print_check "warn" "$param: Not set"
        return
    fi

    echo "$param = $current_value"

    if [ "$current_value" -ge "$min_value" ]; then
        print_check "pass" "$param meets requirements (>= $min_value)"
    else
        print_check "fail" "$param too low: $current_value (minimum $min_value)"
    fi
}

check_kernel_param "kernel.shmmax" "4294967295"
check_kernel_param "kernel.shmall" "2097152"
check_kernel_param "kernel.shmmni" "4096"
check_kernel_param "fs.file-max" "6815744"

echo ""

################################################################################
# 5. REQUIRED PACKAGES
################################################################################
echo -e "${BLUE}[5/8] Required Packages${NC}"
echo "----------------------------------------"

REQUIRED_PACKAGES=(
    "binutils"
    "gcc"
    "gcc-c++"
    "glibc"
    "glibc-devel"
    "libaio"
    "libaio-devel"
    "libstdc++"
    "ksh"
    "motif"
    "libXext"
    "libXtst"
    "unixODBC"
    "unixODBC-devel"
    "zlib-devel"
    "tar"
    "gzip"
    "unzip"
)

for pkg in "${REQUIRED_PACKAGES[@]}"; do
    if rpm -q "$pkg" >/dev/null 2>&1; then
        print_check "pass" "$pkg installed"
    else
        print_check "fail" "$pkg NOT installed"
    fi
done

echo ""

################################################################################
# 6. USER AND PERMISSIONS
################################################################################
echo -e "${BLUE}[6/8] User and Permissions${NC}"
echo "----------------------------------------"

# Current user
CURRENT_USER=$(whoami)
echo "Current user: $CURRENT_USER"

if [ "$CURRENT_USER" = "oracle" ]; then
    print_check "pass" "Running as oracle user"
else
    print_check "warn" "Not running as oracle user (should be 'oracle')"
fi

# Check oracle user exists
if id oracle >/dev/null 2>&1; then
    print_check "pass" "Oracle user exists"
    echo "  UID: $(id -u oracle)"
    echo "  GID: $(id -g oracle)"
    echo "  Groups: $(id -G oracle)"
else
    print_check "fail" "Oracle user does not exist"
fi

# Check directory ownership
if [ -d "/u01/app/oracle" ]; then
    OWNER=$(stat -c '%U' /u01/app/oracle)
    GROUP=$(stat -c '%G' /u01/app/oracle)
    echo "/u01/app/oracle owner: $OWNER:$GROUP"

    if [ "$OWNER" = "oracle" ] && [ "$GROUP" = "oinstall" ]; then
        print_check "pass" "Correct ownership on /u01/app/oracle"
    else
        print_check "fail" "Incorrect ownership on /u01/app/oracle (should be oracle:oinstall)"
    fi
else
    print_check "fail" "/u01/app/oracle directory does not exist"
fi

# Check write permissions
if [ -w "/u01/app/oracle/middleware" ]; then
    print_check "pass" "Write permission on /u01/app/oracle/middleware"
else
    print_check "fail" "No write permission on /u01/app/oracle/middleware"
fi

echo ""

################################################################################
# 7. INSTALLATION FILES
################################################################################
echo -e "${BLUE}[7/8] Installation Files${NC}"
echo "----------------------------------------"

INSTALL_DIR="/install"

if [ -d "$INSTALL_DIR" ]; then
    print_check "pass" "Installation directory exists: $INSTALL_DIR"

    # Check for JDK
    JDK_FILE=$(find $INSTALL_DIR -name "jdk-*_linux-x64_bin.tar.gz" 2>/dev/null | head -1)
    if [ -n "$JDK_FILE" ]; then
        print_check "pass" "JDK file found: $(basename $JDK_FILE)"
    else
        print_check "fail" "JDK file NOT found (jdk-*_linux-x64_bin.tar.gz)"
    fi

    # Check for FMW Infrastructure
    FMW_FILE=$(find $INSTALL_DIR -name "fmw_*_infrastructure.jar" 2>/dev/null | head -1)
    if [ -n "$FMW_FILE" ]; then
        print_check "pass" "FMW Infrastructure found: $(basename $FMW_FILE)"
    else
        print_check "fail" "FMW Infrastructure NOT found (fmw_*_infrastructure.jar)"
    fi

    # Check for Forms & Reports
    FR_FILE=$(find $INSTALL_DIR -name "fmw_*_fr_linux64.bin" 2>/dev/null | head -1)
    if [ -n "$FR_FILE" ]; then
        print_check "pass" "Forms & Reports found: $(basename $FR_FILE)"

        # Check if executable
        if [ -x "$FR_FILE" ]; then
            print_check "pass" "Forms & Reports installer is executable"
        else
            print_check "warn" "Forms & Reports installer not executable (run: chmod +x $FR_FILE)"
        fi
    else
        print_check "fail" "Forms & Reports NOT found (fmw_*_fr_linux64.bin)"
    fi
else
    print_check "fail" "Installation directory does not exist: $INSTALL_DIR"
fi

echo ""

################################################################################
# 8. ENVIRONMENT VARIABLES
################################################################################
echo -e "${BLUE}[8/8] Environment Variables${NC}"
echo "----------------------------------------"

# Display current environment
if [ -n "$ORACLE_BASE" ]; then
    echo "ORACLE_BASE: $ORACLE_BASE"
    print_check "pass" "ORACLE_BASE is set"
else
    echo "ORACLE_BASE: Not set"
    print_check "warn" "ORACLE_BASE not set (will be set during installation)"
fi

if [ -n "$JAVA_HOME" ]; then
    echo "JAVA_HOME: $JAVA_HOME"
    if [ -d "$JAVA_HOME" ]; then
        print_check "pass" "JAVA_HOME is set and directory exists"
    else
        print_check "warn" "JAVA_HOME is set but directory does not exist"
    fi
else
    echo "JAVA_HOME: Not set"
    print_check "warn" "JAVA_HOME not set (will be set after Java installation)"
fi

if [ -n "$ORACLE_HOME" ]; then
    echo "ORACLE_HOME: $ORACLE_HOME"
    if [ -d "$ORACLE_HOME" ]; then
        print_check "warn" "ORACLE_HOME already exists (may indicate previous installation)"
    else
        print_check "pass" "ORACLE_HOME is set"
    fi
else
    echo "ORACLE_HOME: Not set"
    print_check "warn" "ORACLE_HOME not set (will be set during installation)"
fi

echo ""

################################################################################
# SUMMARY
################################################################################
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Pre-Installation Check Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}${CHECK} All checks passed!${NC}"
    echo -e "${GREEN}System is ready for Oracle Forms & Reports 14c installation.${NC}"
    EXIT_CODE=0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}${WARN} ${WARNINGS} warning(s) found${NC}"
    echo -e "${YELLOW}You may proceed, but review warnings above.${NC}"
    EXIT_CODE=0
else
    echo -e "${RED}${CROSS} ${ERRORS} error(s) and ${WARNINGS} warning(s) found${NC}"
    echo -e "${RED}Please fix errors before proceeding with installation.${NC}"
    EXIT_CODE=1
fi

echo ""
echo -e "${BLUE}Installation Paths:${NC}"
echo "  Java: /u01/app/oracle/middleware/jdk17"
echo "  Oracle Home: /u01/app/oracle/middleware/fmw"
echo "  Domain: /u01/app/oracle/middleware/config/domains/forms_domain"
echo ""

exit $EXIT_CODE
