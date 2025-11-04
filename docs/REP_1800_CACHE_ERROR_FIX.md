# Oracle Reports REP-1800 Error - Complete Fix Guide

## Error Description
When accessing Oracle Reports via `http://localhost:9002/reports/rwservlet?report=BLANK.rdf&destype=cache&DESFORMAT=html`:
```
Error REP-1800: A formatter error occurred.
```

## Root Cause Analysis

After investigating the logs, the **actual root cause** is:

```
Error occurred sending Job output to cache
Writeable folders not configured. Output destination to 'File' will fail.
```

**Found in logs:**
- `/u01/app/oracle/config/domains/forms_domain/servers/WLS_REPORTS/logs/reports/rwserver_diagnostic.log`
- `/u01/app/oracle/config/domains/forms_domain/servers/WLS_REPORTS/logs/reports/rwEng-0_diagnostic.log`

### The Real Problem

The REP-1800 error is **NOT caused by insufficient memory**, but by **missing security configuration** for writeable folders. Oracle Reports Server needs explicit permission to write report output to cache directories for security reasons.

Without this configuration:
1. Report generates successfully
2. Formatter creates the output
3. **Writing to cache fails** due to security restrictions
4. REP-1800 error is thrown

## Solution

### Option 1: Configure Through WebLogic Enterprise Manager (Recommended)

1. Access Enterprise Manager Console:
   ```
   http://localhost:7001/em
   Username: weblogic
   Password: Oracle123
   ```

2. Navigate to:
   - WebLogic Domain → forms_domain
   - Right-click on "reports" → System MBean Browser

3. Find Reports Server MBean:
   - Application Defined MBeans → oracle.reports.serverconfig
   - ReportsServer → rep_wls_reports_oracle-forms → rwserver

4. Configure Security:
   - Find `Security` tab or attributes
   - Set `writeableFolders` property to:
     ```
     /u01/app/oracle/config/domains/forms_domain/reports/cache;/tmp;/u01/app/oracle/reports_source
     ```

5. Restart WLS_REPORTS managed server

### Option 2: Configure via WLST Script

Create and run this WLST script:

```python
#!/usr/bin/env python
# configure_reports_writeablefolders.py

connect('weblogic', 'Oracle123', 't3://localhost:7001')

# Edit configuration
edit()
startEdit()

# Navigate to Reports Server Component MBean
cd('/')
cd('Servers/WLS_REPORTS')

# Get the Reports Server configuration MBean path
# Note: The exact MBean path may vary depending on your installation
try:
    # Configure writeable folders through custom WLST commands
    custom()
    cd('/oracle.reports.serverconfig/ReportsServer/rep_wls_reports_oracle-forms/Configuration/rwserver')

    # Set writeable folders
    set('WriteableFolders', '/u01/app/oracle/config/domains/forms_domain/reports/cache;/tmp;/u01/app/oracle/reports_source')

    # Save and activate
    save()
    activate()

    print('SUCCESS: Writeable folders configured')
    print('Please restart WLS_REPORTS managed server')

except Exception as e:
    print('Error configuring writeable folders:')
    print(str(e))
    cancelEdit('y')

disconnect()
```

Run the script:
```bash
docker exec -it oracle-forms-14c bash
cd /u01/app/oracle/product/fmw14.1.2.0/oracle_common/common/bin
./wlst.sh /path/to/configure_reports_writeablefolders.py
```

### Option 3: Manual Configuration File Edit (May Not Persist)

**Note:** This method may not work as runtime security settings are managed by JMX/MBeans.

Edit `/u01/app/oracle/config/domains/forms_domain/config/fmwconfig/servers/WLS_REPORTS/applications/reports_14.1.2/configuration/rwserver.conf`:

```xml
<security id="rwJaznSec" class="oracle.reports.server.RWJAZNSecurity">
   <property name="writeableFolders" value="/u01/app/oracle/config/domains/forms_domain/reports/cache;/tmp;/u01/app/oracle/reports_source"/>
</security>
```

**Then restart the Reports Server.**

### Option 4: Workaround - Use Different Destination

If you cannot configure writeable folders immediately, use a different output destination:

```
# Output to browser (bypasses cache)
http://localhost:9002/reports/rwservlet?report=BLANK.rdf&destype=browser&DESFORMAT=pdf

# Output to printer (if configured)
http://localhost:9002/reports/rwservlet?report=BLANK.rdf&destype=printer&DESFORMAT=pdf
```

## Verification Steps

1. **Check if Reports Server loaded the security configuration:**
   ```bash
   docker exec oracle-forms-14c bash -c "grep -i 'writeable' /u01/app/oracle/config/domains/forms_domain/servers/WLS_REPORTS/logs/reports/rwserver_diagnostic.log | tail -5"
   ```

   Should **NOT** show: "Writeable folders not configured"

2. **Test cache write permissions:**
   ```bash
   docker exec oracle-forms-14c bash -c "ls -la /u01/app/oracle/config/domains/forms_domain/reports/cache/"
   ```

3. **Run a test report:**
   ```
   http://localhost:9002/reports/rwservlet?cbslamconn&report=BLANK.rdf&destype=cache&DESFORMAT=html
   ```

4. **Check for errors:**
   ```bash
   docker exec oracle-forms-14c bash -c "tail -50 /u01/app/oracle/config/domains/forms_domain/servers/WLS_REPORTS/logs/reports/rwEng-0_diagnostic.log"
   ```

   Should **NOT** show:
   - "REP-1800: A formatter error occurred"
   - "Error occurred sending Job output to cache"

## Required Directories

Ensure these directories exist with proper permissions:

```bash
# Create cache directory
docker exec oracle-forms-14c bash -c "mkdir -p /u01/app/oracle/config/domains/forms_domain/reports/cache"
docker exec oracle-forms-14c bash -c "chmod 775 /u01/app/oracle/config/domains/forms_domain/reports/cache"
docker exec oracle-forms-14c bash -c "chown oracle:oinstall /u01/app/oracle/config/domains/forms_domain/reports/cache"

# Verify permissions
docker exec oracle-forms-14c bash -c "ls -la /u01/app/oracle/config/domains/forms_domain/reports/"
```

## Permanent Fix for Docker Builds

Add to your Dockerfile or startup script:

```dockerfile
# Create Reports cache directory with proper permissions
RUN mkdir -p /u01/app/oracle/config/domains/forms_domain/reports/cache && \
    chmod 775 /u01/app/oracle/config/domains/forms_domain/reports/cache && \
    chown oracle:oinstall /u01/app/oracle/config/domains/forms_domain/reports/cache

# Copy pre-configured rwserver.conf with security settings
COPY scripts/rwserver.conf /u01/app/oracle/config/domains/forms_domain/config/fmwconfig/servers/WLS_REPORTS/applications/reports_14.1.2/configuration/rwserver.conf
```

## Understanding the Error

### Why This Happens

Oracle Reports 14c (FMW 14.1.2) has enhanced security features that prevent unauthorized file system access. By default:

- Reports Server **cannot write** to file system locations
- This includes cache directories, temp directories, and output folders
- You must explicitly configure "writeable folders" through security settings

### Error Flow

1. User requests report with `destype=cache`
2. Reports Engine generates the report successfully
3. Formatter creates output (PDF/HTML/etc.)
4. System attempts to write output to cache directory
5. **Security check fails** - directory not in writeable folders list
6. Write operation blocked
7. REP-1800 error thrown: "A formatter error occurred"

### Why It's Confusing

The error message "REP-1800: A formatter error occurred" is misleading:
- The **formatter** works fine
- The **security/write check** fails
- The generic "formatter error" is thrown

## Additional Troubleshooting

### If Error Persists

1. **Check JAZN Security is Active:**
   ```bash
   docker exec oracle-forms-14c bash -c "grep -A 5 'rwJaznSec' /u01/app/oracle/config/domains/forms_domain/config/fmwconfig/servers/WLS_REPORTS/applications/reports_14.1.2/configuration/rwserver.conf"
   ```

2. **Verify Reports Server is Using In-Process Mode:**
   ```bash
   docker exec oracle-forms-14c bash -c "grep -i 'inprocess' /u01/app/oracle/config/domains/forms_domain/config/fmwconfig/servers/WLS_REPORTS/applications/reports_14.1.2/configuration/rwservlet.properties"
   ```

   Should show: `<inprocess>yes</inprocess>`

3. **Check for File System Permissions:**
   ```bash
   docker exec oracle-forms-14c bash -c "su - oracle -c 'touch /u01/app/oracle/config/domains/forms_domain/reports/cache/test.txt && rm /u01/app/oracle/config/domains/forms_domain/reports/cache/test.txt && echo SUCCESS || echo FAILED'"
   ```

4. **Review Full Error Stack:**
   ```bash
   docker exec oracle-forms-14c bash -c "tail -200 /u01/app/oracle/config/domains/forms_domain/servers/WLS_REPORTS/logs/reports/rwEng-0_diagnostic.log | grep -A 20 'REP-1800'"
   ```

## Common Mistakes

1. ❌ **Modifying wrong rwserver.conf file**
   - There are multiple rwserver.conf files in the installation
   - The active one is in: `/config/fmwconfig/servers/WLS_REPORTS/applications/`

2. ❌ **Not restarting the Reports Server**
   - Configuration changes require restart

3. ❌ **Using semicolon separator incorrectly**
   - Multiple paths: use `;` not `:` or `,`
   - Correct: `/path1;/path2;/path3`

4. ❌ **Assuming it's a memory issue**
   - REP-1800 has multiple causes
   - Always check logs for the specific error

## References

- Oracle Reports 14c Security Guide
- Oracle Support Document: REP-1800 Error Resolution (Doc ID 2118748.1)
- WebLogic Server MBean Reference Guide
- Oracle Fusion Middleware Administering Oracle Reports

## Summary

The REP-1800 error when using `destype=cache` is caused by:
- ✅ **Missing writeable folders security configuration**
- ❌ NOT memory issues
- ❌ NOT missing report files
- ❌ NOT database connectivity

**Fix:** Configure writeable folders through Enterprise Manager or WLST, then restart Reports Server.
