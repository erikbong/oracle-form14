# Oracle Reports Server Configuration Guide

## Summary of Issues Fixed

During troubleshooting of the REP-52266 error, the following configuration issues were identified and resolved:

### 1. Missing Directories ✅ FIXED
- Created `/u01/app/oracle/config/domains/forms_domain/reports/cache`
- Created `/u01/app/oracle/config/domains/forms_domain/reports/server`
- Created `/u01/app/oracle/config/domains/forms_domain/reports/bin`

### 2. rwserver.conf Configuration ✅ FIXED
Updated the Reports Server configuration file to specify:
- **cacheDir**: `/u01/app/oracle/config/domains/forms_domain/reports/cache`
- **sourceDir**: `/u01/app/oracle/reports_source`
- **tempDir**: `/tmp`

Location: `/u01/app/oracle/config/domains/forms_domain/servers/WLS_REPORTS/tmp/_WL_user/reports_14.1.2/4mx3gr/configuration/rwserver.conf`

### 3. rwengine.sh Script ✅ CREATED
Created a configured rwengine.sh script at:
`/u01/app/oracle/config/domains/forms_domain/reports/bin/rwengine.sh`

## Current Status

**WLS_REPORTS Managed Server**: ✅ RUNNING
**Reports Application (reports_14.1.2)**: ✅ DEPLOYED
**In-Process Reports Server**: ⚠️ NOT STARTING

The Reports Engine (rwEng-0) is being launched but terminates immediately without detailed error messages.

## Root Cause Analysis

The **in-process Reports Server** mode requires additional configuration that is typically done through:
1. Oracle Enterprise Manager Fusion Middleware Control
2. WLST configuration scripts
3. Manual system component configuration

The in-process mode relies on the rwengine.sh script to spawn engine processes, but these processes need proper Java classpaths, library paths, and environment variables that are normally set up during system component configuration.

## Recommended Solution: Configure Standalone Reports Server

### Option 1: Using Enterprise Manager (Recommended)

1. **Access Enterprise Manager**
   ```
   URL: http://localhost:7001/em
   Username: weblogic
   Password: Oracle123
   ```

2. **Navigate to Reports Configuration**
   - Left panel: Expand "WebLogic Domain" → "forms_domain"
   - Right-click on "forms_domain" → "System MBean Browser"

3. **Create Reports Server Instance**
   - Navigate to: Application Defined MBeans → oracle.as.management.mbeans.register
   - Configure a new Reports Server system component

4. **Start the Reports Server**
   - Once configured, the Reports Server can be started via EM Control panel

### Option 2: Using WLST (Alternative)

Create a WLST script to configure the Reports Server component:

```python
# Connect to Admin Server
connect('weblogic','Oracle123','t3://localhost:7001')

# Connect to Node Manager
nmConnect('weblogic','Oracle123','localhost','5556','forms_domain')

# Start Reports Server (if configured)
nmStart('rep_server1','ReportsServerComponent')

disconnect()
nmDisconnect()
exit()
```

### Option 3: Configure via VNC Configuration Wizard (Most Reliable)

Since your domain was created via the Configuration Wizard, you can also configure Reports Server components using the same wizard:

1. **Connect to VNC**
   ```
   Host: localhost:5901
   Password: Oracle123
   ```

2. **Run Configuration Wizard**
   ```bash
   cd /u01/app/oracle/product/fmw14.1.2.0/oracle_common/common/bin
   ./config.sh
   ```

3. **Update Domain**
   - Choose: "Update an existing domain"
   - Select: forms_domain
   - Configure: Reports Server component
   - Specify: Server name, port, and instance directory

## Testing Reports

### About BATCH-TEMPORARY.jsp

The report file `BATCH-TEMPORARY.jsp` does not currently exist in the system. Oracle Reports files typically have `.rdf` extensions, not `.jsp`.

**To test Reports Server once configured:**

1. **Place a .rdf file in** `/u01/app/oracle/reports_source/`

2. **Test via rwservlet:**
   ```bash
   http://localhost:9002/reports/rwservlet?report=myreport.rdf&userid=username/password@TNSNAME&desformat=pdf&destype=cache
   ```

3. **Test via rwrun (command line):**
   ```bash
   docker exec oracle-forms-14c rwrun report=/u01/app/oracle/reports_source/myreport.rdf userid=username/password@TNSNAME destype=file desname=/tmp/output.pdf desformat=pdf
   ```

## Database Connections Available

The following TNS connections are configured in `/tns_admin/tnsnames.ora`:

- **FREEPDB1**: Local Oracle 23c Free database (oracle-db:1521)
- **TOS19**: 46.137.238.154:1522 (tos19 service)
- **TOS19PDB**: 46.137.238.154:1522 (tos19pdb service)
- **BNCTDEV**: dev.1eagledb.bnct-id.com:1521 (ORCLPDB1 service)

## Next Steps

1. **Verify report file exists**: Check if BATCH-TEMPORARY exists as .rdf or another format
2. **Choose configuration method**: EM, WLST, or Configuration Wizard
3. **Configure Reports Server component**: Create standalone Reports Server instance
4. **Start Reports Server**: Via EM, nmStart, or Node Manager
5. **Test with a valid .rdf report**: Use one of the database connections above

## Useful Commands

### Check Reports Server Status
```bash
docker exec oracle-forms-14c bash -c "source /u01/app/oracle/product/fmw14.1.2.0/wlserver/server/bin/setWLSEnv.sh && java weblogic.WLST << 'EOF'
connect('weblogic','Oracle123','t3://localhost:7001')
domainRuntime()
cd('/ServerRuntimes/WLS_REPORTS/ApplicationRuntimes')
ls()
disconnect()
exit()
EOF"
```

### Check Reports Logs
```bash
# Reports Server diagnostic log
docker exec oracle-forms-14c tail -f /u01/app/oracle/config/domains/forms_domain/servers/WLS_REPORTS/logs/reports/rwserver_diagnostic.log

# Reports Servlet diagnostic log
docker exec oracle-forms-14c tail -f /u01/app/oracle/config/domains/forms_domain/servers/WLS_REPORTS/logs/reports/rwservlet_diagnostic.log

# WLS_REPORTS server log
docker exec oracle-forms-14c tail -f /u01/app/oracle/config/domains/forms_domain/servers/WLS_REPORTS/logs/WLS_REPORTS.log
```

### Restart WLS_REPORTS
```bash
docker exec oracle-forms-14c bash -c "source /u01/app/oracle/product/fmw14.1.2.0/wlserver/server/bin/setWLSEnv.sh && java weblogic.WLST << 'EOF'
connect('weblogic','Oracle123','t3://localhost:7001')
shutdown('WLS_REPORTS','Server')
start('WLS_REPORTS','Server')
disconnect()
exit()
EOF"
```

## References

- Oracle Reports Documentation: https://docs.oracle.com/en/middleware/developer-tools/reports/14.1.2/
- WebLogic Server Administration Guide
- Enterprise Manager Fusion Middleware Control Guide

---

**Last Updated**: 2025-10-31
**Status**: In-process Reports Server not functional - requires proper system component configuration
