# Oracle Forms & Reports 14c - Production Deployment Guide

## Overview

This production setup provides a complete, ready-to-run Oracle Forms & Reports 14c environment with:

✅ **Oracle installation baked into Docker image** - No manual installation needed
✅ **Oracle Database included** - Separate container for data persistence
✅ **Auto-start services** - All services start automatically
✅ **Externally mounted configs** - Easy customization without rebuilding
✅ **Network connectivity** - Forms/Reports automatically connect to database
✅ **Production-ready** - Resource limits, health checks, logging

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  oracle-forms-production (Forms & Reports Container)        │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  - Oracle FMW 14.1.2.0 (baked in)                    │   │
│  │  - WebLogic AdminServer (port 7001)                  │   │
│  │  - WLS_FORMS (port 9001)                             │   │
│  │  │  - WLS_REPORTS (port 9012 → exposed as 9002)       │   │
│  │  - VNC Server (port 5901)                            │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                              │
│  Mounted Configs (externally editable):                     │
│  - ./config/forms/    → Forms configuration                 │
│  - ./config/reports/  → Reports configuration               │
│  - ./config/tnsnames/ → Database connection strings         │
│  - ./forms_source/    → Your .fmb files                     │
│  - ./reports_source/  → Your .rdf files                     │
└─────────────────────────────────────────────────────────────┘
                           ↓ connects to
┌─────────────────────────────────────────────────────────────┐
│  oracle-db-production (Database Container)                  │
│  - Oracle Database 23c Free (port 1521)                     │
│  - Service: FREEPDB1                                        │
│  - RCU User: rcu_user/Oracle123                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Quick Start

### Prerequisites

1. **Docker and Docker Compose** installed
2. **./Oracle directory** with your working installation
3. **At least 16GB RAM** available for Docker
4. **50GB disk space** for images and data

### Step 1: Prepare Configuration Files

The production image has Oracle installation baked in, but you can customize configurations:

```bash
# Create config directories (already done)
mkdir -p config/forms config/reports config/tnsnames logs
```

### Step 2: Copy Configuration Template

```bash
# Copy environment configuration
cp .env.production .env

# Edit credentials (IMPORTANT in production!)
# Change WLS_PW, DB_PASSWORD, VNC_PASSWORD
```

### Step 3: Build Production Image

This will copy your ./Oracle folder into the Docker image:

```bash
# Build the production image (takes 10-15 minutes first time)
docker-compose -f docker-compose.production.yml build
```

**Note:** The build copies the entire ./Oracle directory into the image. This is a one-time operation.

### Step 4: Start All Services

```bash
# Start database and Forms/Reports containers
docker-compose -f docker-compose.production.yml up -d

# Monitor startup (services take 3-5 minutes to be ready)
docker logs -f oracle-forms-production
```

### Step 5: Verify Services

After 5 minutes, check that all services are running:

```bash
# Check logs
docker logs oracle-forms-production

# Check service status
docker exec -u oracle oracle-forms-production ps aux | grep weblogic

# Access WebLogic Console
# http://localhost:7001/console (weblogic/Oracle123)
```

---

## Service URLs

Once all services are started (wait 5-8 minutes):

### Direct Access:
- **VNC Desktop**: `vnc://localhost:5901` (password: Oracle123)
- **WebLogic Console**: http://localhost:7001/console
- **Enterprise Manager**: http://localhost:7001/em
- **Forms**: http://localhost:9001/forms/frmservlet
- **Reports**: http://localhost:9002/reports/rwservlet
- **Oracle Database**: `localhost:1521/FREEPDB1`

### With Nginx Proxy (use `--profile proxy`):
- **Admin Console**: http://localhost:8880/console
- **Forms**: http://localhost:8880/forms
- **Reports**: http://localhost:8880/reports

---

## Configuration Management

### Forms Configuration

Place Forms-specific config files in `./config/forms/`:
- `default.env` - Forms runtime environment variables
- `formsweb.cfg` - Forms servlet configuration
- Custom environment files

### Reports Configuration

Place Reports-specific config files in `./config/reports/`:
- `rwserver.conf` - Reports Server configuration
- `rwnetwork.conf` - Reports Network configuration
- `rwbuilder.conf` - Reports Builder configuration

### Database Connection (TNS Names)

Create `./config/tnsnames/tnsnames.ora`:

```
FREEPDB1 =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = oracle-db)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = FREEPDB1)
    )
  )
```

Then update docker-compose.production.yml to mount it:
```yaml
- ./config/tnsnames/tnsnames.ora:/u01/app/oracle/middleware/fmw/network/admin/tnsnames.ora:ro
```

---

## Working with Forms and Reports

### Deploy Forms (.fmb files)

```bash
# Copy your .fmb files to forms_source directory
cp myform.fmb ./forms_source/

# Connect via VNC and compile
# or use Forms Builder in VNC session
```

### Deploy Reports (.rdf files)

```bash
# Copy your .rdf files to reports_source directory
cp myreport.rdf ./reports_source/

# The files are accessible inside the container at:
# /home/oracle/reports_source/myreport.rdf
```

---

## Container Management

### Start Services

```bash
# Start all services (db + forms/reports)
docker-compose -f docker-compose.production.yml up -d

# Start with nginx proxy
docker-compose -f docker-compose.production.yml --profile proxy up -d

# View logs
docker-compose -f docker-compose.production.yml logs -f
```

### Stop Services

```bash
# Gracefully stop Oracle services first (recommended)
docker exec -u oracle oracle-forms-production /u01/app/oracle/middleware/stopAllServices.sh

# Stop containers
docker-compose -f docker-compose.production.yml down

# Stop and remove volumes (⚠️ deletes database data!)
docker-compose -f docker-compose.production.yml down -v
```

### Restart Services

```bash
# Restart everything
docker-compose -f docker-compose.production.yml restart

# Restart only Forms/Reports
docker-compose -f docker-compose.production.yml restart oracle-forms
```

---

## Monitoring

### Check Service Status

```bash
# View container logs
docker logs -f oracle-forms-production

# Check running processes
docker exec -u oracle oracle-forms-production ps aux | grep weblogic

# Check specific service logs
docker exec oracle-forms-production tail -f /u01/app/oracle/middleware/logs/adminserver.log
docker exec oracle-forms-production tail -f /u01/app/oracle/middleware/logs/wls_forms.log
docker exec oracle-forms-production tail -f /u01/app/oracle/middleware/logs/wls_reports.log
```

### Health Checks

Docker automatically monitors services:

```bash
# Check health status
docker ps --format "table {{.Names}}\t{{.Status}}"

# View health check logs
docker inspect oracle-forms-production | grep -A 10 Health
```

---

## Customization

### Disable Auto-Start

Edit `.env`:
```bash
AUTO_START_SERVICES=false
```

Then restart:
```bash
docker-compose -f docker-compose.production.yml restart
```

### Change Resource Limits

Edit `.env`:
```bash
MEM_LIMIT=16g          # Maximum memory
MEM_RESERVATION=12g    # Reserved memory
CPUS=6                 # CPU cores
SHM_SIZE=4gb           # Shared memory
```

### Change Ports

Edit `.env`:
```bash
ADMIN_PORT=8001
FORMS_PORT=8002
REPORTS_PORT=8003
```

---

## Troubleshooting

### Services Don't Start

**Check logs:**
```bash
docker logs oracle-forms-production
```

**Common issues:**
- Not enough memory (increase MEM_LIMIT)
- Database not ready (wait for oracle-db to be healthy)
- Port conflicts (change ports in .env)

### Cannot Access WebLogic Console

**Check if AdminServer is running:**
```bash
docker exec -u oracle oracle-forms-production ps aux | grep AdminServer
```

**Check if port is exposed:**
```bash
docker ps | grep oracle-forms-production
```

**Try accessing via VNC:**
- Connect to VNC: `vnc://localhost:5901`
- Open Firefox inside VNC
- Navigate to http://localhost:7001/console

### Database Connection Issues

**Verify database is running:**
```bash
docker logs oracle-db-production
docker exec oracle-db-production healthcheck.sh
```

**Test connection from Forms container:**
```bash
docker exec -u oracle oracle-forms-production sqlplus rcu_user/Oracle123@oracle-db:1521/FREEPDB1
```

### Forms/Reports Not Starting

**Check managed server logs:**
```bash
docker exec oracle-forms-production cat /u01/app/oracle/middleware/logs/wls_forms.log
docker exec oracle-forms-production cat /u01/app/oracle/middleware/logs/wls_reports.log
```

**Manually restart services:**
```bash
docker exec -u oracle oracle-forms-production /u01/app/oracle/middleware/stopAllServices.sh
docker exec -u oracle oracle-forms-production /u01/app/oracle/middleware/startAllServices.sh
```

---

## Backup and Recovery

### Backup Production Image

```bash
# Save the production image
docker save oracle-forms-14c-production:latest | gzip > oracle-forms-production-backup.tar.gz

# Backup database
docker exec oracle-db-production sh -c 'expdp rcu_user/Oracle123@FREEPDB1 full=y directory=DATA_PUMP_DIR dumpfile=backup.dmp'
```

### Backup Configuration Files

```bash
# Backup configs (Windows PowerShell)
Compress-Archive -Path .\config -DestinationPath ".\backups\config-$(Get-Date -Format 'yyyyMMdd').zip"

# Or using Git Bash/WSL
tar -czf "./backups/config-$(date +%Y%m%d).tar.gz" ./config ./forms_source ./reports_source
```

### Restore from Backup

```bash
# Load image
docker load < oracle-forms-production-backup.tar.gz

# Restore configs
Expand-Archive -Path ".\backups\config-20251104.zip" -DestinationPath .

# Start services
docker-compose -f docker-compose.production.yml up -d
```

---

## Upgrading

### Rebuild After Oracle Changes

If you make changes to the ./Oracle directory:

```bash
# Stop services
docker-compose -f docker-compose.production.yml down

# Rebuild image (will copy new Oracle directory)
docker-compose -f docker-compose.production.yml build --no-cache

# Start services
docker-compose -f docker-compose.production.yml up -d
```

### Update Only Configuration

If you only changed config files (no rebuild needed):

```bash
# Just restart the container
docker-compose -f docker-compose.production.yml restart oracle-forms
```

---

## Production Best Practices

1. **Change default passwords** in .env file
2. **Use SSL/TLS** for external access (configure nginx with certificates)
3. **Regular backups** of database and config files
4. **Monitor logs** for errors and performance issues
5. **Resource monitoring** - ensure sufficient memory and CPU
6. **Update .env** - never commit passwords to version control
7. **Use volumes** for database data persistence
8. **Health checks** - Docker automatically monitors services
9. **Logging rotation** - configured in docker-compose (10MB x 3 files)

---

## Differences from Manual Setup

| Feature | Manual Setup | Production Setup |
|---------|-------------|------------------|
| Oracle Installation | Mounted from host `./Oracle/` | Baked into Docker image |
| Installation Time | Persists on host | Copied during build (one-time) |
| Container Size | Small (~2GB) | Large (~10GB with Oracle) |
| Startup Time | 3-5 minutes | 3-5 minutes |
| Configuration Files | Can edit directly in ./Oracle/ | Mounted from ./config/ |
| Database | Not included | Included (oracle-db) |
| Portability | Requires ./Oracle/ directory | Fully self-contained image |
| Updates | Edit files in ./Oracle/, restart | Rebuild image if Oracle changes |

---

## Next Steps

1. ✅ Review `.env.production` and customize settings
2. ✅ Build production image: `docker-compose -f docker-compose.production.yml build`
3. ✅ Start services: `docker-compose -f docker-compose.production.yml up -d`
4. ✅ Monitor logs: `docker logs -f oracle-forms-production`
5. ✅ Access console: http://localhost:7001/console
6. ✅ Deploy your Forms (.fmb) and Reports (.rdf) files
7. ✅ Test connectivity between Forms/Reports and Database
8. ✅ Set up backups and monitoring

---

## Support

For issues or questions:
- Check logs: `docker logs oracle-forms-production`
- View processes: `docker exec -u oracle oracle-forms-production ps aux`
- Connect via VNC for troubleshooting: `vnc://localhost:5901`
- Review [AUTO_START_GUIDE.md](AUTO_START_GUIDE.md) for service management
- Review [BACKUP_GUIDE.md](BACKUP_GUIDE.md) for backup procedures

---

**You now have a complete, production-ready Oracle Forms & Reports 14c environment!** 🚀
