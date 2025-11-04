# Oracle Forms & Reports 14c - Complete Installation Guide

This comprehensive guide documents the **successful installation** of Oracle Forms & Reports 14c in Docker, from start to finish.

---

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Manual Installation Method](#manual-installation-method)
4. [Production Deployment](#production-deployment)
5. [Docker Hub Distribution](#docker-hub-distribution)
6. [Access and Verification](#access-and-verification)
7. [Troubleshooting](#troubleshooting)

---

## Overview

### What You'll Build

A complete Oracle Forms & Reports 14c environment with:
- ✅ Oracle Forms 14.1.2.0
- ✅ Oracle Reports 14.1.2.0
- ✅ WebLogic Server 14.1.2.0
- ✅ Java 17 (JDK 17.0.12)
- ✅ WebLogic Domain with AdminServer, Forms Server, Reports Server
- ✅ VNC Desktop (XFCE4) for GUI access
- ✅ Auto-start capability
- ✅ Production-ready Docker image

### Installation Path

```
Manual Installation (Development)
         ↓
Working ./Oracle/ Directory
         ↓
Production Image (Deployment)
         ↓
Docker Hub (Distribution)
```

---

## Prerequisites

### System Requirements

**Hardware:**
- CPU: 4+ cores recommended
- RAM: 16GB minimum, 24GB recommended
- Disk: 60GB free space minimum

**Software:**
- Docker Desktop or Docker Engine (20.10+)
- Docker Compose (v2.0+)
- VNC Client (TigerVNC, RealVNC, TightVNC, or built-in)
- Git (optional, for cloning repository)

### Oracle Installation Files

Download from [Oracle Technology Network](https://www.oracle.com/middleware/technologies/fusionmiddleware-downloads.html):

1. **JDK 17** (Oracle Java SE)
   - File: `jdk-17.0.12_linux-x64_bin.tar.gz` (~180MB)
   - Version: 17.0.12 or later

2. **Fusion Middleware Infrastructure** (WebLogic + JRF)
   - File: `fmw_14.1.2.0.0_infrastructure.jar` (~2.1GB)
   - Version: 14.1.2.0

3. **Forms and Reports**
   - File: `fmw_14.1.2.0.0_fr_linux64.bin` (~1.3GB)
   - Version: 14.1.2.0

**Place all files in `./install/` directory**

---

## Manual Installation Method

This is the **recommended starting point**. You'll install Oracle manually via VNC, then convert to production image.

### Step 1: Clone Repository

```bash
git clone https://github.com/erikbong/oracle-form14.git
cd oracle-form14
```

### Step 2: Prepare Environment

```bash
# Create directories
mkdir -p Oracle install forms_source reports_source reports_temp logs config/forms config/reports config/tnsnames

# Copy environment file
cp .env.manual .env

# Edit .env if needed (ports, passwords, etc.)
```

### Step 3: Place Installation Files

```bash
# Copy Oracle installer files to install directory
cp /path/to/jdk-17.0.12_linux-x64_bin.tar.gz ./install/
cp /path/to/fmw_14.1.2.0.0_infrastructure.jar ./install/
cp /path/to/fmw_14.1.2.0.0_fr_linux64.bin ./install/
```

### Step 4: Build and Start Container

```bash
# Build the base container
docker-compose -f docker-compose.manual.yml build

# Start container
docker-compose -f docker-compose.manual.yml up -d

# Wait 30-60 seconds for VNC to start
docker logs oracle-forms-manual-install
```

### Step 5: Connect via VNC

```
VNC Address: localhost:5901
Password: Oracle123
```

**VNC Clients:**
- Windows: Download TigerVNC or RealVNC
- Mac: Use built-in Screen Sharing (vnc://localhost:5901)
- Linux: `vncviewer localhost:5901`

### Step 6: Install Java (in VNC Terminal)

Open terminal in VNC desktop:

```bash
cd /install

# Extract JDK
tar -xzf jdk-17.0.12_linux-x64_bin.tar.gz

# Move to middleware directory
mv jdk-17.0.12 /u01/app/oracle/middleware/jdk17

# Verify
/u01/app/oracle/middleware/jdk17/bin/java -version
```

Expected output: `java version "17.0.12"`

### Step 7: Install FMW Infrastructure

```bash
cd /install

# Launch installer
/u01/app/oracle/middleware/jdk17/bin/java -jar fmw_14.1.2.0.0_infrastructure.jar
```

**Installation Settings:**
- Installation Location: `/u01/app/oracle/middleware/fmw`
- Installation Type: **Fusion Middleware Infrastructure**
- Inventory Directory: `/u01/app/oraInventory`

**Click through:**
1. Installation Inventory Setup → OK
2. Welcome → Next
3. Auto Updates → Skip
4. Installation Location → Enter path → Next
5. Installation Type → Fusion Middleware Infrastructure → Next
6. Prerequisite Checks → Wait for completion → Next
7. Security Updates → Uncheck, Yes to continue → Next
8. Installation Summary → Install
9. Installation Progress → Wait (~15-20 minutes)
10. Installation Complete → Finish

**Verify:**
```bash
ls -la /u01/app/oracle/middleware/fmw/
```

Should see: `oracle_common/`, `wlserver/`, `oui/`, etc.

### Step 8: Install Forms and Reports

```bash
cd /install

# Make installer executable
chmod +x fmw_14.1.2.0.0_fr_linux64.bin

# Launch installer
./fmw_14.1.2.0.0_fr_linux64.bin
```

**Installation Settings:**
- Oracle Home: `/u01/app/oracle/middleware/fmw` (SAME as Infrastructure)
- Installation Type: **Forms and Reports**

**Click through:**
1. Welcome → Next
2. Auto Updates → Skip
3. Installation Location → Enter `/u01/app/oracle/middleware/fmw` → Next
4. Installation Type → Forms and Reports → Next
5. Prerequisite Checks → Wait → Next
6. Installation Summary → Install
7. Installation Progress → Wait (~10-15 minutes)
8. Installation Complete → Finish

**Verify:**
```bash
ls -la /u01/app/oracle/middleware/fmw/forms/
ls -la /u01/app/oracle/middleware/fmw/reports/
```

### Step 9: Create WebLogic Domain

```bash
cd /u01/app/oracle/middleware/fmw/oracle_common/common/bin

# Launch Configuration Wizard
./config.sh
```

**Domain Configuration:**

1. **Configuration Type:**
   - Select: **Create a new domain**
   - Domain Location: `/u01/app/oracle/middleware/fmw/user_projects/domains/base_domain`
   - Click Next

2. **Templates:**
   - Select:
     - ✅ **Oracle JRF** (WebLogic Coherence Cluster Extension required)
     - ✅ **Oracle Forms**
     - ✅ **Oracle Reports Application**
     - ✅ **Oracle Reports Server**
     - ✅ **Oracle Enterprise Manager** (optional but recommended)
   - Click Next

3. **Administrator Account:**
   - Name: `weblogic`
   - Password: `Oracle123`
   - Confirm: `Oracle123`
   - Click Next

4. **Domain Mode and JDK:**
   - Domain Mode: **Development** (for dev) or **Production**
   - JDK: `/u01/app/oracle/middleware/jdk17`
   - Click Next

5. **Database Configuration:**
   - RCU Data: Select **Ignore** (we'll configure later if needed)
   - Or if you have database ready:
     - DBMS/Service: `oracle-db:1521/FREEPDB1`
     - Host Name: `oracle-db`
     - Port: `1521`
     - Schema Owner: `DEV_STB`
     - Schema Password: `Oracle123`
   - Click Next

6. **Advanced Configuration:**
   - Select:
     - ✅ **Administration Server**
     - ✅ **Node Manager**
     - ✅ **Managed Servers, Clusters and Coherence**
   - Click Next

7. **Administration Server:**
   - Listen Address: `All Local Addresses`
   - Listen Port: `7001`
   - Enable SSL: Unchecked
   - Click Next

8. **Node Manager:**
   - Type: **Per Domain Default Location**
   - Click Next

9. **Managed Servers:**
   - Verify two servers exist:
     - `WLS_FORMS` - Port: `9001`
     - `WLS_REPORTS` - Port: `9012` (important: 9012, not 9002)
   - Click Next

10. **Clusters:** (Optional)
    - Skip or create cluster if needed
    - Click Next

11. **Server Templates:** (If shown)
    - Skip
    - Click Next

12. **Coherence Clusters:** (If shown)
    - Skip
    - Click Next

13. **Machines:** (Optional)
    - Create machine if using Node Manager
    - Click Next

14. **Assign Servers to Machines:**
    - Assign all servers to created machine
    - Click Next

15. **Configuration Summary:**
    - Review all settings
    - Click **Create**

16. **Configuration Progress:**
    - Wait for domain creation (~5-10 minutes)
    - Status should show 100% Complete
    - Click **Finish**

**Verify Domain:**
```bash
ls -la /u01/app/oracle/middleware/fmw/user_projects/domains/base_domain/
```

Should see: `bin/`, `config/`, `servers/`, etc.

### Step 10: Create Service Startup Scripts

Create startup scripts in `/u01/app/oracle/middleware/`:

**1. Start All Services Script:**

```bash
cat > /u01/app/oracle/middleware/startAllServices.sh << 'EOF'
#!/bin/bash
################################################################################
# Oracle Forms & Reports 14c - Start All Services
################################################################################

RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
NC="\033[0m"

DOMAIN_HOME="/u01/app/oracle/middleware/fmw/user_projects/domains/base_domain"
LOG_DIR="/u01/app/oracle/middleware/logs"
MW_HOME="/u01/app/oracle/middleware"

mkdir -p "$LOG_DIR"

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

is_process_running() {
    ps aux | grep -v grep | grep "$1" > /dev/null 2>&1
    return $?
}

echo "================================================================================"
echo "  Oracle Forms & Reports 14c - Service Startup"
echo "================================================================================"
echo ""

cd "$DOMAIN_HOME/bin" || exit 1

# Step 1: Start NodeManager
print_info "Step 1/4: Starting NodeManager..."
if is_process_running "weblogic.NodeManager"; then
    print_warning "NodeManager is already running"
else
    nohup ./startNodeManager.sh > "$LOG_DIR/nodemanager.log" 2>&1 &
    sleep 5
    if is_process_running "weblogic.NodeManager"; then
        print_success "NodeManager started successfully"
    else
        echo "Failed to start NodeManager. Check: $LOG_DIR/nodemanager.log"
        exit 1
    fi
fi
echo ""

# Step 2: Start AdminServer
print_info "Step 2/4: Starting AdminServer..."
if is_process_running "weblogic.Name=AdminServer"; then
    print_warning "AdminServer is already running"
else
    nohup ./startWebLogic.sh > "$LOG_DIR/adminserver.log" 2>&1 &
    print_success "AdminServer is starting (will take 3-5 minutes to be fully ready)"
    print_info "Waiting 30 seconds before starting managed servers..."
    sleep 30
fi
echo ""

# Step 3: Start WLS_FORMS
print_info "Step 3/4: Starting WLS_FORMS..."
if is_process_running "weblogic.Name=WLS_FORMS"; then
    print_warning "WLS_FORMS is already running"
else
    nohup "$MW_HOME/startWLS_FORMS.sh" > "$LOG_DIR/wls_forms.log" 2>&1 &
    sleep 5
    print_success "WLS_FORMS is starting"
fi
echo ""

# Step 4: Start WLS_REPORTS
print_info "Step 4/4: Starting WLS_REPORTS..."
if is_process_running "weblogic.Name=WLS_REPORTS"; then
    print_warning "WLS_REPORTS is already running"
else
    nohup "$MW_HOME/startWLS_REPORTS.sh" > "$LOG_DIR/wls_reports.log" 2>&1 &
    sleep 5
    print_success "WLS_REPORTS is starting"
fi
echo ""

echo "================================================================================"
print_success "All services have been started!"
echo "================================================================================"
echo ""
echo "Service URLs (available after full startup):"
echo "  - WebLogic Console:   http://localhost:7001/console"
echo "  - Enterprise Manager: http://localhost:7001/em"
echo "  - Forms:              http://localhost:9001/forms/frmservlet"
echo "  - Reports:            http://localhost:9002/reports/rwservlet"
echo ""
echo "Credentials: weblogic / Oracle123"
echo ""
echo "Note: Services will be fully ready in 5-8 minutes total"
echo ""
EOF

chmod +x /u01/app/oracle/middleware/startAllServices.sh
```

**2. Stop All Services Script:**

```bash
cat > /u01/app/oracle/middleware/stopAllServices.sh << 'EOF'
#!/bin/bash
################################################################################
# Oracle Forms & Reports 14c - Stop All Services
################################################################################

DOMAIN_HOME="/u01/app/oracle/middleware/fmw/user_projects/domains/base_domain"

echo "================================================================================"
echo "  Oracle Forms & Reports 14c - Service Shutdown"
echo "================================================================================"
echo ""

cd "$DOMAIN_HOME/bin" || exit 1

# Stop WLS_REPORTS
echo "[1/4] Stopping WLS_REPORTS..."
./stopManagedWebLogic.sh WLS_REPORTS || pkill -f "weblogic.Name=WLS_REPORTS"
echo ""

# Stop WLS_FORMS
echo "[2/4] Stopping WLS_FORMS..."
./stopManagedWebLogic.sh WLS_FORMS || pkill -f "weblogic.Name=WLS_FORMS"
echo ""

# Stop AdminServer
echo "[3/4] Stopping AdminServer..."
./stopWebLogic.sh || pkill -f "weblogic.Name=AdminServer"
echo ""

# Stop NodeManager
echo "[4/4] Stopping NodeManager..."
./stopNodeManager.sh || pkill -f "weblogic.NodeManager"
echo ""

echo "================================================================================"
echo "  All services stopped!"
echo "================================================================================"
EOF

chmod +x /u01/app/oracle/middleware/stopAllServices.sh
```

**3. Start WLS_FORMS Script:**

```bash
cat > /u01/app/oracle/middleware/startWLS_FORMS.sh << 'EOF'
#!/bin/bash
DOMAIN_HOME="/u01/app/oracle/middleware/fmw/user_projects/domains/base_domain"
export WLS_USER=weblogic
export WLS_PW=Oracle123
cd "$DOMAIN_HOME/bin"
./startManagedWebLogic.sh WLS_FORMS http://localhost:7001
EOF

chmod +x /u01/app/oracle/middleware/startWLS_FORMS.sh
```

**4. Start WLS_REPORTS Script:**

```bash
cat > /u01/app/oracle/middleware/startWLS_REPORTS.sh << 'EOF'
#!/bin/bash
DOMAIN_HOME="/u01/app/oracle/middleware/fmw/user_projects/domains/base_domain"
export WLS_USER=weblogic
export WLS_PW=Oracle123
cd "$DOMAIN_HOME/bin"
./startManagedWebLogic.sh WLS_REPORTS http://localhost:7001
EOF

chmod +x /u01/app/oracle/middleware/startWLS_REPORTS.sh
```

### Step 11: Start Services and Verify

```bash
# Start all services
/u01/app/oracle/middleware/startAllServices.sh

# Wait 5-8 minutes for all services to start

# Check running services
ps aux | grep weblogic
```

You should see 4 Java processes:
1. NodeManager
2. AdminServer
3. WLS_FORMS
4. WLS_REPORTS

**Access WebLogic Console:**
- Open Firefox in VNC
- Navigate to: http://localhost:7001/console
- Login: weblogic / Oracle123

**Verify in Console:**
- Click "Servers" in left navigation
- All servers should show "RUNNING" state:
  - AdminServer: RUNNING
  - WLS_FORMS: RUNNING
  - WLS_REPORTS: RUNNING

**Test Forms:**
- Navigate to: http://localhost:9001/forms/frmservlet
- Should see Forms servlet page

**Test Reports:**
- Navigate to: http://localhost:9002/reports/rwservlet
- Should see Reports servlet page

### Step 12: Configure Auto-Start

The container is already configured with auto-start via `entrypoint.sh`. When you restart the container, all services will start automatically.

**Test Auto-Start:**
```bash
# Exit VNC

# Stop container (from host machine)
docker-compose -f docker-compose.manual.yml down

# Start container
docker-compose -f docker-compose.manual.yml up -d

# Wait 5-8 minutes and check logs
docker logs -f oracle-forms-manual-install

# Services should auto-start!
```

**Verify:**
```bash
# Check processes
docker exec -u oracle oracle-forms-manual-install ps aux | grep weblogic

# Access console
# http://localhost:7001/console
```

---

## Production Deployment

Once your manual installation is working, create a production-ready image.

### Step 1: Verify Manual Installation

Ensure everything is working:
- ✅ All services start successfully
- ✅ Can access WebLogic Console
- ✅ Forms and Reports are accessible
- ✅ Auto-start works on container restart

### Step 2: Create Production Image

```bash
# Stop manual container
docker-compose -f docker-compose.manual.yml down

# Copy production files from docs
cp docs/deployment/Dockerfile.production ./
cp docs/deployment/docker-compose.production.yml ./
cp docs/deployment/.env.production ./.env
cp docs/deployment/entrypoint.sh ./

# Edit .env and change passwords!
# IMPORTANT: Change WLS_PW, DB_PASSWORD, VNC_PASSWORD

# Build production image (copies ./Oracle/ into image)
docker-compose -f docker-compose.production.yml build
```

This creates a self-contained image (~10GB) with your Oracle installation baked in.

### Step 3: Test Production Image

```bash
# Start production setup
docker-compose -f docker-compose.production.yml up -d

# Monitor startup
docker logs -f oracle-forms-production

# Wait 5-8 minutes for all services

# Verify all services
docker exec -u oracle oracle-forms-production ps aux | grep weblogic

# Access console
# http://localhost:7001/console
```

---

## Docker Hub Distribution

Share your production image via Docker Hub.

### Step 1: Tag for Docker Hub

```bash
# Set your Docker Hub username
export DOCKERHUB_USERNAME=your-dockerhub-username

# Tag image
docker tag oracle-forms-14c-production:latest ${DOCKERHUB_USERNAME}/oracle-forms-reports:latest
docker tag oracle-forms-14c-production:latest ${DOCKERHUB_USERNAME}/oracle-forms-reports:14c
```

### Step 2: Push to Docker Hub

```bash
# Login
docker login

# Push image (takes 30-60 minutes)
docker push ${DOCKERHUB_USERNAME}/oracle-forms-reports:latest
docker push ${DOCKERHUB_USERNAME}/oracle-forms-reports:14c
```

### Step 3: Use on Other Machines

On any machine with Docker:

```bash
# Pull image
docker pull your-username/oracle-forms-reports:latest

# Start with docker-compose
docker-compose -f docker-compose.production.yml up -d

# Or use docker-compose.hub.yml (see DOCKERHUB_GUIDE.md)
```

---

## Access and Verification

### Service URLs

Once all services are running:

| Service | URL | Credentials |
|---------|-----|-------------|
| **VNC Desktop** | vnc://localhost:5901 | Oracle123 |
| **WebLogic Console** | http://localhost:7001/console | weblogic/Oracle123 |
| **Enterprise Manager** | http://localhost:7001/em | weblogic/Oracle123 |
| **Forms Servlet** | http://localhost:9001/forms/frmservlet | - |
| **Reports Servlet** | http://localhost:9002/reports/rwservlet | - |
| **Oracle Database** | localhost:1521/FREEPDB1 | rcu_user/Oracle123 |

### Verification Checklist

- [ ] VNC connection works
- [ ] WebLogic Console accessible
- [ ] All servers show "RUNNING" status
- [ ] Forms servlet responds
- [ ] Reports servlet responds
- [ ] Enterprise Manager accessible
- [ ] Auto-start works after container restart

---

## Troubleshooting

### Services Won't Start

**Check logs:**
```bash
docker logs oracle-forms-manual-install
docker exec oracle-forms-manual-install cat /u01/app/oracle/middleware/logs/adminserver.log
```

**Common issues:**
- Insufficient memory (need 12GB+)
- Port conflicts (check ports 7001, 9001, 9002, 1521, 5901)
- Permissions (ensure oracle user owns /u01/app/oracle/)

### Cannot Access WebLogic Console

**From host machine:**
- Check if AdminServer is running: `docker exec -u oracle oracle-forms-manual-install ps aux | grep AdminServer`
- Check if port is mapped: `docker ps | grep 7001`
- Try from VNC first: Open Firefox in VNC, navigate to http://localhost:7001/console

**If accessible from VNC but not host:**
- Firewall issue on host
- Docker network configuration

### Forms/Reports Not Starting

**Check managed server logs:**
```bash
docker exec oracle-forms-manual-install cat /u01/app/oracle/middleware/logs/wls_forms.log
docker exec oracle-forms-manual-install cat /u01/app/oracle/middleware/logs/wls_reports.log
```

**Common causes:**
- AdminServer not fully started (wait longer)
- Incorrect credentials in startup scripts
- Missing boot.properties files

**Fix:**
Ensure credentials are set in startup scripts:
```bash
export WLS_USER=weblogic
export WLS_PW=Oracle123
```

### Auto-Start Not Working

**Check entrypoint:**
```bash
docker logs oracle-forms-manual-install
```

Should see:
- "Starting VNC server..."
- "Auto-starting Oracle services..."
- Service startup messages

**If not starting:**
- Check AUTO_START_SERVICES=true in .env
- Verify /u01/app/oracle/middleware/startAllServices.sh exists and is executable
- Check entrypoint.sh is mounted correctly

### Container Crashes on Startup

**Check resource limits:**
```bash
docker stats
```

Ensure:
- Memory limit: 12GB minimum
- Shared memory: 2GB minimum

**Increase resources in docker-compose:**
```yaml
mem_limit: 16g
mem_reservation: 12g
shm_size: 4gb
```

---

## Summary

You now have:

✅ **Working Manual Installation** - Development environment with VNC access
✅ **Production Docker Image** - Self-contained, portable image
✅ **Auto-Start Capability** - Services start automatically
✅ **Docker Hub Ready** - Can push and share with team
✅ **Complete Documentation** - All steps documented

### Next Steps

1. **Development**: Use manual setup, iterate on Forms/Reports development
2. **Production**: Build production image from working manual installation
3. **Distribution**: Push to Docker Hub for team deployment
4. **Deployment**: Deploy using docker-compose.production.yml

See also:
- [deployment/PRODUCTION_GUIDE.md](deployment/PRODUCTION_GUIDE.md) - Production deployment details
- [deployment/DOCKERHUB_GUIDE.md](deployment/DOCKERHUB_GUIDE.md) - Docker Hub push/pull guide
- [deployment/BACKUP_GUIDE.md](deployment/BACKUP_GUIDE.md) - Backup and recovery
- [configuration/DOMAIN_CREATION_GUIDE.md](configuration/DOMAIN_CREATION_GUIDE.md) - Detailed domain creation
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Common issues and solutions

**Your Oracle Forms & Reports 14c installation is complete!** 🎉
