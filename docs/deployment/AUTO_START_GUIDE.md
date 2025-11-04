# Oracle Forms & Reports 14c - Auto-Start Configuration

## Overview

The docker-compose.manual.yml has been updated to **automatically start all Oracle services** when the container starts. No more manual startup required!

---

## What's New

✅ **Auto-start on container startup** - Services start automatically
✅ **New volume mappings** - Dedicated folders for Forms and Reports files
✅ **Environment variable control** - Easy enable/disable of auto-start
✅ **Health monitoring** - Container logs show service startup progress

---

## New Directory Structure

```
oracle_form_14c/
├── Oracle/                  # Oracle middleware (domain, config, logs)
├── forms_source/           # Your Forms .fmb files (NEW!)
├── reports_source/         # Your Reports .rdf files (NEW!)
├── reports_temp/           # Reports temporary files (NEW!)
├── install/                # Oracle installation files
└── scripts/                # Utility scripts
```

---

## Configuration

### Enable/Disable Auto-Start

Edit `.env` file:

```bash
# Enable auto-start (default)
AUTO_START_SERVICES=true

# Disable auto-start (VNC only)
AUTO_START_SERVICES=false
```

### Port Mapping Update

The Reports port has been corrected:

```yaml
ports:
  - "7001:7001"     # WebLogic Admin Console
  - "9001:9001"     # Forms Server
  - "9002:9012"     # Reports Server (container uses 9012)
```

---

## How It Works

When the container starts:

1. **VNC Server** starts (allows GUI access)
2. **Wait 10 seconds** (let VNC initialize)
3. **Auto-start services** (if enabled):
   - NodeManager
   - AdminServer
   - WLS_FORMS
   - WLS_REPORTS
4. **Tail logs** (keeps container running)

**Total startup time**: ~6-8 minutes for all services to be fully ready

---

## Usage

### Start Container (Services Auto-Start)

```bash
# All services will start automatically
docker-compose -f docker-compose.manual.yml up -d

# Monitor startup progress
docker logs -f oracle-forms-manual-install
```

### Start Container (No Auto-Start)

```bash
# Set in .env first
AUTO_START_SERVICES=false

# Start container (VNC only)
docker-compose -f docker-compose.manual.yml up -d

# Manually start services later via VNC
/u01/app/oracle/middleware/startAllServices.sh
```

### Restart Container

```bash
# Stop services gracefully first (recommended)
docker exec -u oracle oracle-forms-manual-install /u01/app/oracle/middleware/stopAllServices.sh

# Restart container (services will auto-start)
docker-compose -f docker-compose.manual.yml restart

# Or full restart
docker-compose -f docker-compose.manual.yml down
docker-compose -f docker-compose.manual.yml up -d
```

---

## Monitoring

### Check Service Status

```bash
# View startup logs
docker logs -f oracle-forms-manual-install

# Check running services
docker exec oracle-forms-manual-install ps aux | grep weblogic

# Check specific logs
docker exec oracle-forms-manual-install tail -f /u01/app/oracle/middleware/logs/adminserver.log
docker exec oracle-forms-manual-install tail -f /u01/app/oracle/middleware/logs/wls_forms.log
docker exec oracle-forms-manual-install tail -f /u01/app/oracle/middleware/logs/wls_reports.log
```

### Access Services

Once started (wait 6-8 minutes after container startup):

- **VNC**: `vnc://localhost:5901` (password: Oracle123)
- **WebLogic Console**: http://localhost:7001/console
- **Enterprise Manager**: http://localhost:7001/em
- **Forms**: http://localhost:9001/forms/frmservlet
- **Reports**: http://localhost:9002/reports/rwservlet

---

## Troubleshooting

### Services Don't Start Automatically

Check if auto-start is enabled:
```bash
docker exec oracle-forms-manual-install env | grep AUTO_START
```

Check startup script exists:
```bash
docker exec oracle-forms-manual-install ls -la /u01/app/oracle/middleware/startAllServices.sh
```

### Services Fail to Start

Check logs for errors:
```bash
docker logs oracle-forms-manual-install
```

Manually start services via VNC:
```bash
# Connect to VNC, open terminal
/u01/app/oracle/middleware/startAllServices.sh
```

### Container Keeps Restarting

Disable auto-start to troubleshoot:
```bash
# In .env
AUTO_START_SERVICES=false

# Restart container
docker-compose -f docker-compose.manual.yml restart

# Connect via VNC to investigate
```

---

## Benefits

✅ **No manual startup** - Services start automatically
✅ **Faster deployment** - One command to start everything
✅ **Better for production** - Services restart automatically on reboot
✅ **Container health** - Logs show service status
✅ **Organized files** - Separate folders for Forms and Reports

---

## Migration from Old Setup

If you're upgrading from the previous configuration:

1. ✅ **Backup created** - `oracle-forms-14c-configured:latest`
2. ✅ **Volumes persist** - `./Oracle/` contains all installations
3. ✅ **New folders created** - `forms_source`, `reports_source`, `reports_temp`
4. ✅ **Ready to restart** - Use commands below

---

## Ready to Test?

Restart your container with the new configuration:

```bash
# Stop services gracefully
docker exec -u oracle oracle-forms-manual-install /u01/app/oracle/middleware/stopAllServices.sh

# Restart with new config
docker-compose -f docker-compose.manual.yml down
docker-compose -f docker-compose.manual.yml up -d

# Monitor startup (wait 6-8 minutes)
docker logs -f oracle-forms-manual-install
```

Your services will start automatically! 🚀

---

## Notes

- **First startup**: May take longer as services initialize
- **Subsequent startups**: Faster as configurations are cached
- **Health checks**: Container monitors VNC service
- **Graceful shutdown**: Always stop services before removing container
- **Backup**: Image snapshot created for safety
