# Reports Configuration Directory

This directory is for Reports-specific configuration files that you want to externally mount and customize.

## Common Configuration Files

### rwserver.conf
Reports Server configuration file. Controls:
- Server name and identification
- Port configuration
- Job queue settings
- Cache settings
- Security settings

Example location in container:
```
/u01/app/oracle/middleware/fmw/reports/conf/rwserver.conf
```

### rwnetwork.conf
Reports Network configuration. Defines:
- Network connections
- Server endpoints
- Load balancing

### rwbuilder.conf
Reports Builder configuration for development environment.

## Example rwserver.conf Snippet

```xml
<server>
    <name>rep_wls_reports</name>
    <port>9012</port>
    <engine id="rwEng" class="oracle.reports.engine.EngineImpl">
        <property name="sourceDir" value="/home/oracle/reports_source"/>
        <property name="tempDir" value="/home/oracle/reports_temp"/>
        <property name="cacheDir" value="/home/oracle/reports_temp/cache"/>
    </engine>
</server>
```

## Mounting Configuration Files

To mount Reports configuration files, update `docker-compose.production.yml`:

```yaml
volumes:
  # Example: Mount rwserver.conf
  - ./config/reports/rwserver.conf:/u01/app/oracle/middleware/fmw/reports/conf/rwserver.conf:ro

  # Example: Mount rwnetwork.conf
  - ./config/reports/rwnetwork.conf:/u01/app/oracle/middleware/fmw/reports/conf/rwnetwork.conf:ro
```

## Important Settings

### Source Directory
Where Reports looks for .rdf files:
```xml
<property name="sourceDir" value="/home/oracle/reports_source"/>
```

### Temp Directory
Where Reports stores temporary files:
```xml
<property name="tempDir" value="/home/oracle/reports_temp"/>
```

### Database Connection
Reports uses TNS names from `/u01/app/oracle/middleware/config/tnsnames/tnsnames.ora`

## Usage

1. Extract current configuration from running container:
   ```bash
   docker cp oracle-forms-production:/u01/app/oracle/middleware/fmw/reports/conf/rwserver.conf ./config/reports/
   ```

2. Modify the configuration as needed

3. Update docker-compose.production.yml to mount the file

4. Restart the container:
   ```bash
   docker-compose -f docker-compose.production.yml restart oracle-forms
   ```

## Testing Configuration

After updating configuration:

```bash
# Check if Reports Server is running
docker exec -u oracle oracle-forms-production ps aux | grep WLS_REPORTS

# View Reports Server logs
docker exec oracle-forms-production tail -f /u01/app/oracle/middleware/logs/wls_reports.log

# Test Reports servlet
curl http://localhost:9002/reports/rwservlet
```

## Notes

- Reports Server runs on container port 9012 (exposed as 9002)
- Configuration changes require container restart
- Always backup configuration files before modifications
- Use `:ro` for read-only mounts in production
