# Oracle Forms & Reports 14c Installation Guide

This guide provides detailed instructions for setting up and deploying Oracle Forms & Reports 14c using Docker.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Obtaining Oracle Installation Files](#obtaining-oracle-installation-files)
- [System Requirements](#system-requirements)
- [Step-by-Step Installation](#step-by-step-installation)
- [Verification](#verification)
- [Post-Installation Configuration](#post-installation-configuration)
- [Troubleshooting Installation Issues](#troubleshooting-installation-issues)

## Prerequisites

### Required Software

- **Docker Desktop** (Windows/Mac) or **Docker Engine** (Linux)
- **Docker Compose** v3.8+
- **Git** for repository management
- **Oracle Account** for downloading installation files

### System Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| **RAM** | 8 GB | 16 GB |
| **CPU** | 4 cores | 8 cores |
| **Storage** | 50 GB free | 100 GB free |
| **Network** | Internet for downloads | High-speed connection |

### Docker Configuration

Ensure Docker has sufficient resources:

```bash
# Check Docker resources
docker info | grep -E "(Total Memory|CPUs)"

# Recommended Docker Desktop settings:
# Memory: 8 GB minimum
# CPUs: 4 cores minimum
# Disk: 50 GB minimum
```

## Obtaining Oracle Installation Files

### Required Files

You need three Oracle installation files:

1. **Oracle JDK 17**
   - File: `jdk-17.0.12_linux-x64_bin.tar.gz`
   - Size: ~180 MB
   - Source: https://www.oracle.com/java/technologies/downloads/

2. **Oracle FMW Infrastructure**
   - File: `fmw_14.1.2.0.0_infrastructure.jar`
   - Size: ~2.1 GB
   - Source: Oracle Technology Network

3. **Oracle Forms & Reports**
   - File: `fmw_14.1.2.0.0_fr_linux64.bin`
   - Size: ~1.3 GB
   - Source: Oracle Technology Network

### Download Instructions

1. **Create Oracle Account**
   - Visit https://profile.oracle.com/
   - Create free account if you don't have one
   - Accept Oracle Technology Network License Agreement

2. **Download Oracle JDK 17**
   ```
   URL: https://www.oracle.com/java/technologies/downloads/
   → Java 17 → Linux x64 Compressed Archive
   → Download jdk-17.0.12_linux-x64_bin.tar.gz
   ```

3. **Download Oracle FMW Infrastructure**
   ```
   URL: https://www.oracle.com/middleware/technologies/fusion-middleware-downloads.html
   → Oracle Fusion Middleware 14c
   → Oracle Fusion Middleware Infrastructure 14.1.2.0.0
   → Linux x86-64: fmw_14.1.2.0.0_infrastructure.jar
   ```

4. **Download Oracle Forms & Reports**
   ```
   URL: https://www.oracle.com/middleware/technologies/forms/downloads.html
   → Oracle Forms and Reports 14c (14.1.2.0.0)
   → Linux x86-64: fmw_14.1.2.0.0_fr_linux64.bin
   ```

### File Verification

Verify downloaded files:

```bash
# Check file sizes (approximate)
ls -lh install/
# jdk-17.0.12_linux-x64_bin.tar.gz    ~180M
# fmw_14.1.2.0.0_infrastructure.jar   ~2.1G
# fmw_14.1.2.0.0_fr_linux64.bin       ~1.3G

# Verify file integrity (if checksums available)
sha256sum install/*
```

## Step-by-Step Installation

### Step 1: Clone Repository

```bash
# Clone the repository
git clone https://github.com/erikbong/oracle-form14.git
cd oracle-form14

# Verify repository contents
ls -la
# Should see: Dockerfile, docker-compose.yml, scripts/, response/, etc.
```

### Step 2: Prepare Installation Files

```bash
# Create install directory (if not exists)
mkdir -p install

# Copy downloaded Oracle files to install directory
cp /path/to/downloads/jdk-17.0.12_linux-x64_bin.tar.gz install/
cp /path/to/downloads/fmw_14.1.2.0.0_infrastructure.jar install/
cp /path/to/downloads/fmw_14.1.2.0.0_fr_linux64.bin install/

# Verify files are in place
ls -la install/
```

### Step 3: Configure Environment

```bash
# Copy environment template
cp .env.example .env

# Edit configuration (optional)
nano .env
```

Key settings to review:
```bash
# WebLogic Admin Credentials (CHANGE FOR PRODUCTION!)
ADMIN_USERNAME=weblogic
ADMIN_PASSWORD=Oracle123

# Resource limits
MEMORY_LIMIT=4G
CPU_LIMIT=2.0

# External ports (change if conflicts exist)
EXTERNAL_ADMIN_PORT=7001
EXTERNAL_FORMS_PORT=9001
EXTERNAL_REPORTS_PORT=9002
```

### Step 4: Build and Deploy

#### Option A: Basic Deployment

```bash
# Build and start Oracle Forms
docker-compose up -d

# Monitor build progress
docker-compose logs -f oracle-forms
```

#### Option B: Full Stack with Nginx Proxy

```bash
# Build and start with reverse proxy
docker-compose --profile proxy up -d

# Monitor all services
docker-compose logs -f
```

### Step 5: Monitor Installation Progress

The build process takes 10-15 minutes. Monitor progress:

```bash
# Watch build logs
docker-compose logs -f oracle-forms

# Check container status
docker-compose ps

# Monitor resource usage
docker stats
```

Build stages you'll see:
1. **OS Package Installation** (~2 minutes)
2. **Oracle User/Directory Setup** (~1 minute)
3. **JDK Extraction** (~1 minute)
4. **FMW Infrastructure Installation** (~5-7 minutes)
5. **Domain Creation** (~2-3 minutes)
6. **Service Startup** (~2-3 minutes)

## Verification

### Step 1: Check Container Health

```bash
# Verify containers are running
docker-compose ps

# Should show:
# oracle-forms-14c    Up (healthy)
# oracle-forms-proxy  Up (if using proxy profile)
```

### Step 2: Test Service Access

```bash
# Test WebLogic Console (wait 2-3 minutes after startup)
curl -f http://localhost:7001/console

# Test Forms Service
curl -f http://localhost:9001

# Test Reports Service
curl -f http://localhost:9002
```

### Step 3: Access WebLogic Console

1. Open browser: http://localhost:7001/console
2. Login with credentials:
   - Username: `weblogic`
   - Password: `Oracle123` (or your custom password)
3. Verify domain shows:
   - AdminServer (Running)
   - forms_server1 (Running)
   - reports_server1 (Running)

### Step 4: Test Nginx Proxy (if enabled)

```bash
# Test proxy access
curl -f http://localhost/console
curl -f http://localhost/forms
curl -f http://localhost/reports
```

## Post-Installation Configuration

### Security Configuration

1. **Change Default Password**
   ```bash
   # Update .env file
   ADMIN_PASSWORD=YourSecurePassword123!

   # Recreate containers
   docker-compose down
   docker-compose up -d
   ```

2. **Restrict Network Access**
   ```yaml
   # docker-compose.override.yml
   services:
     oracle-forms:
       ports:
         - "127.0.0.1:7001:7001"  # Localhost only
   ```

### Performance Tuning

1. **Adjust JVM Settings**
   ```bash
   # .env file
   JAVA_OPTIONS=-Xmx4096m -Xms2048m -XX:+UseG1GC
   ```

2. **Resource Limits**
   ```yaml
   # docker-compose.override.yml
   services:
     oracle-forms:
       deploy:
         resources:
           limits:
             memory: 6G
             cpus: '3.0'
   ```

### Data Persistence

Verify persistent volumes:
```bash
# List Oracle volumes
docker volume ls | grep oracle

# Backup domain data
docker run --rm -v oracle_domain_data:/data -v $(pwd):/backup \
  alpine tar czf /backup/domain-backup.tar.gz -C /data .
```

## Troubleshooting Installation Issues

### Build Failures

#### Issue: Package Installation Fails
```
Error: Failed to download packages
```
**Solution:**
- Check internet connectivity
- Retry with: `docker-compose build --no-cache`
- Increase Docker memory allocation

#### Issue: Oracle File Not Found
```
COPY failed: stat install/fmw_14.1.2.0.0_infrastructure.jar: no such file
```
**Solution:**
- Verify files are in `install/` directory
- Check filename matches exactly (case-sensitive)
- Ensure files aren't corrupted

#### Issue: JDK Extraction Fails
```
tar: gzip: Cannot exec: No such file or directory
```
**Solution:**
- This is already fixed in current Dockerfile
- Ensure you're using latest version from repository

### Runtime Issues

#### Issue: Container Exits Immediately
```bash
# Check logs
docker-compose logs oracle-forms

# Common causes:
# - Insufficient memory
# - Port conflicts
# - Domain creation failure
```

#### Issue: WebLogic Console Not Accessible
```bash
# Wait for full startup (2-3 minutes)
# Check if services are starting
docker-compose exec oracle-forms ps aux | grep java

# Check port binding
docker port $(docker-compose ps -q oracle-forms)
```

#### Issue: Out of Memory
```
Container killed (exit code 137)
```
**Solution:**
- Increase Docker memory to 8GB+
- Reduce JVM heap size
- Add system swap space

### Advanced Debugging

```bash
# Access container for debugging
docker-compose exec oracle-forms bash

# Check WebLogic logs
tail -f /u01/app/oracle/config/domains/forms_domain/servers/AdminServer/logs/AdminServer.log

# Check domain status
cd /u01/app/oracle/config/domains/forms_domain
./bin/startWebLogic.sh

# Check system resources
free -h
df -h
```

### Getting Help

If you encounter issues:

1. **Check logs**: `docker-compose logs oracle-forms`
2. **Review documentation**: [README.md](README.md)
3. **Search issues**: https://github.com/erikbong/oracle-form14/issues
4. **Create issue**: Include logs and system information

## Next Steps

After successful installation:

1. **Review [README.md](README.md)** for usage information
2. **Configure applications** in WebLogic Console
3. **Set up monitoring** and logging
4. **Plan backup strategy** for persistent data
5. **Consider SSL/TLS** for production deployment

---

**Installation complete!** Your Oracle Forms & Reports 14c environment is ready for development and deployment.