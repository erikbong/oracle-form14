# WebLogic 14.1.2 Console Access Guide

## Overview

Oracle WebLogic Server 14.1.2 has replaced the traditional web-based administration console with the **WebLogic Remote Console** - a modern, standalone desktop application.

## Console Access Options

### 1. WebLogic Remote Console (Recommended)

**Download & Install:**
1. Visit the WebLogic Console welcome page: http://localhost:7001/console
2. Click "Download WebLogic Remote Console"
3. Download the installer for your platform (Windows, macOS, Linux)
4. Install and run the application

**Connect to Your Server:**
- Host: `localhost`
- Port: `7001`
- Username: `weblogic`
- Password: `Oracle123`

### 2. Command Line Administration (WLST)

Access WebLogic Scripting Tool directly in the container:

```bash
# Enter the container
docker exec -it oracle-forms-14c bash

# Run WLST
cd /u01/app/oracle/product/fmw14.1.2.0/oracle_common/common/bin
./wlst.sh

# Connect to AdminServer
connect('weblogic', 'Oracle123', 't3://localhost:7001')

# Example commands
domainRuntime()
ls()
exit()
```

### 3. REST Management API

WebLogic 14.1.2 provides comprehensive REST APIs for management:

```bash
# Get server status
curl -u weblogic:Oracle123 \
  http://localhost:7001/management/weblogic/latest/domainRuntime/serverLifeCycleRuntimes

# Get domain information
curl -u weblogic:Oracle123 \
  http://localhost:7001/management/weblogic/latest/domainConfig
```

## Access URLs

- **Console Welcome**: http://localhost:7001/console
- **REST API Base**: http://localhost:7001/management/weblogic/latest/
- **Server Health**: http://localhost:7001/weblogic/ready

## With Nginx Proxy (Optional)

If using `docker-compose --profile proxy up`:

- **Console Welcome**: http://localhost/console
- **Admin via subdomain**: http://admin.localhost

## Managing Servers

### Start/Stop Managed Servers

Using WLST:
```python
connect('weblogic', 'Oracle123', 't3://localhost:7001')
start('WLS_FORMS', 'Server')
start('WLS_REPORTS', 'Server')
```

Using REST API:
```bash
# Start Forms Server
curl -X POST -u weblogic:Oracle123 \
  http://localhost:7001/management/weblogic/latest/domainRuntime/serverLifeCycleRuntimes/WLS_FORMS/start

# Check server status
curl -u weblogic:Oracle123 \
  http://localhost:7001/management/weblogic/latest/domainRuntime/serverRuntimes/WLS_FORMS
```

## Troubleshooting

### Check Server Status
```bash
docker logs oracle-forms-14c --tail 50
```

### Access Container Logs
```bash
docker exec oracle-forms-14c tail -f /u01/app/oracle/config/domains/forms_domain/servers/AdminServer/logs/AdminServer.log
```

### Verify Services
```bash
curl http://localhost:7001/console  # Should redirect to welcome page
curl http://localhost:9001/         # Forms server
curl http://localhost:9002/         # Reports server
```

## Security Considerations

⚠️ **Important**: The default credentials (`weblogic`/`Oracle123`) are for development only.

For production:
1. Change admin password immediately
2. Configure SSL/TLS
3. Set up proper authentication realms
4. Restrict network access

## Additional Resources

- [Oracle WebLogic Remote Console Documentation](https://docs.oracle.com/en/middleware/fusion-middleware/weblogic-remote-console/)
- [WebLogic Server REST API Reference](https://docs.oracle.com/en/middleware/fusion-middleware/weblogic-server/12.2.1.4/wlrur/)
- [WLST Command Reference](https://docs.oracle.com/en/middleware/fusion-middleware/weblogic-server/12.2.1.4/wlstc/)