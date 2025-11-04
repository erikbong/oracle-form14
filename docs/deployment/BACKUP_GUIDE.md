# Oracle Forms & Reports 14c - Backup & Restore Guide

## Overview

This guide explains how to backup and restore your Oracle Forms & Reports 14c Docker container to ensure you can recover your configuration if something goes wrong.

## What Gets Backed Up

1. **Container State**: Complete container filesystem with all installed software
2. **Oracle Middleware**: All files in `./Oracle/` directory (domain, configurations, logs)
3. **Forms/Reports Source**: Your `.fmb` and `.rdf` files (if stored in mapped volumes)

---

## Quick Backup (Already Done!)

✅ **A snapshot has already been created for you:**
- Image: `oracle-forms-14c-configured:latest`
- Size: 8.9GB
- Contains: All current configuration and state

---

## Backup Methods

### Method 1: Quick Snapshot (Recommended for Testing)

**When to use:** Before making changes, testing updates, or restarting container

```bash
# Create snapshot
docker commit oracle-forms-manual-install oracle-forms-14c-configured:$(date +%Y%m%d_%H%M%S)
docker tag oracle-forms-14c-configured:$(date +%Y%m%d_%H%M%S) oracle-forms-14c-configured:latest
```

**To restore:**
```bash
# Stop current container
docker-compose -f docker-compose.manual.yml down

# Update docker-compose.manual.yml to use the saved image:
# Change: build: ...
# To:     image: oracle-forms-14c-configured:latest

# Start with saved image
docker-compose -f docker-compose.manual.yml up -d
```

---

### Method 2: Full Backup (Recommended for Long-term Storage)

**When to use:** Regular backups, before major changes, archival

```bash
# Run the backup script (Windows Git Bash or WSL)
bash backup-container.sh
```

**This creates:**
- `backups/oracle-forms-14c-YYYYMMDD_HHMMSS.tar.gz` (~3-4GB compressed)
- `backups/oracle-volumes-YYYYMMDD_HHMMSS.tar.gz` (~2-3GB compressed)

**To restore:**
```bash
# List available backups
bash restore-container.sh

# Restore specific backup
bash restore-container.sh 20251104_143000
```

---

### Method 3: Volume-Only Backup (Quickest)

**When to use:** You only want to backup configuration/data, not the entire container

```bash
# Backup Oracle directory (Windows PowerShell)
Compress-Archive -Path .\Oracle -DestinationPath ".\backups\Oracle-backup-$(Get-Date -Format 'yyyyMMdd_HHmmss').zip"

# Or using tar (Git Bash/WSL)
tar -czf "./backups/Oracle-backup-$(date +%Y%m%d_%H%M%S).tar.gz" ./Oracle
```

**To restore:**
```bash
# Extract to Oracle directory
tar -xzf ./backups/Oracle-backup-YYYYMMDD_HHMMSS.tar.gz
```

---

## What's Persistent (Already Safe)

These are **already backed up** because they're in mapped volumes on your Windows host:

✅ `./Oracle/` - All Oracle middleware installations and domain configuration
✅ `./forms_source/` - Your Forms `.fmb` files
✅ `./reports_source/` - Your Reports `.rdf` files
✅ `./reports_temp/` - Reports temporary files

**Even if the container is deleted**, these files remain on your Windows filesystem.

---

## Safe Restart Procedure

To restart the container with your new docker-compose configuration:

### Option A: Using Current Container (No Backup Restore Needed)

```bash
# 1. Stop services gracefully
docker exec -u oracle oracle-forms-manual-install /u01/app/oracle/middleware/stopAllServices.sh

# 2. Stop and remove container
docker-compose -f docker-compose.manual.yml down

# 3. Start with new configuration
docker-compose -f docker-compose.manual.yml up -d

# 4. Wait 2 minutes for container to initialize, then start services
docker exec -u oracle oracle-forms-manual-install /u01/app/oracle/middleware/startAllServices.sh
```

### Option B: Using Saved Image (Guaranteed Working State)

```bash
# 1. Stop current container
docker-compose -f docker-compose.manual.yml down

# 2. Update docker-compose.manual.yml:
# Under oracle-forms-manual:
#   Comment out "build:" section
#   Add: image: oracle-forms-14c-configured:latest

# 3. Start with saved image
docker-compose -f docker-compose.manual.yml up -d

# 4. Services should auto-start or run:
docker exec -u oracle oracle-forms-manual-install /u01/app/oracle/middleware/startAllServices.sh
```

---

## Emergency Recovery

If container fails to start after restart:

### 1. Check logs
```bash
docker logs oracle-forms-manual-install
```

### 2. Restore from snapshot
```bash
docker-compose -f docker-compose.manual.yml down
# Update docker-compose.manual.yml to use: oracle-forms-14c-configured:latest
docker-compose -f docker-compose.manual.yml up -d
```

### 3. Verify Oracle directory
```bash
# Check that Oracle directory still has your installation
ls -la ./Oracle/fmw/
ls -la ./Oracle/jdk17/
```

---

## Best Practices

1. **Before major changes**: Create snapshot with `docker commit`
2. **Weekly backups**: Run `backup-container.sh`
3. **Keep multiple backups**: Don't overwrite previous backups
4. **Test restore**: Periodically test that backups work
5. **External storage**: Copy backups to external drive or cloud storage

---

## Current Backup Status

✅ **Snapshot Created**: `oracle-forms-14c-configured:latest` (8.9GB)
✅ **Volumes Persistent**: `./Oracle/` on Windows host
✅ **Safe to Restart**: Yes, your data is protected

---

## Restart Container Now

You can safely restart with your new configuration:

```bash
# Graceful stop
docker exec -u oracle oracle-forms-manual-install /u01/app/oracle/middleware/stopAllServices.sh
docker-compose -f docker-compose.manual.yml down

# Start with new configuration
docker-compose -f docker-compose.manual.yml up -d

# Wait 2 minutes, then start services
docker exec -u oracle oracle-forms-manual-install /u01/app/oracle/middleware/startAllServices.sh
```

Your configuration is safe! The `./Oracle/` directory on your Windows machine contains all your installations and will be automatically mounted when the container restarts.
