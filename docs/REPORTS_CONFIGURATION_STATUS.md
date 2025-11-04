# Oracle Reports Server Configuration Status

## Current Status Summary

**Date**: November 3, 2025
**Container**: oracle-forms-14c
**Reports Server**: WLS_REPORTS (Running on port 9012, mapped to 9002)

### ✅ What's Working

1. **Database Connection**: oracle-db container is running and accessible
2. **AdminServer**: Running successfully on port 7001
3. **WLS_REPORTS Managed Server**: Running in RUNNING mode
4. **Reports Servlet**: Accessible at `http://172.19.0.2:9012/reports/rwservlet`
5. **OHS Configuration**: Updated via `ohs_updateInstances()`
6. **Reports Tools Instance**: Created successfully (`reptools1`)
7. **Memory Settings**: Increased from 512MB to 2GB
8. **Cache Directory**: Created with proper permissions

### ❌ What's NOT Working

1. **In-Process Reports Server Engine**: rwEng-0 keeps dying
2. **Writeable Folders Configuration**: Not applied at runtime
3. **Report Generation**: Failing with REP-52266 and REP-1800 errors

## Current Error Messages

```
REP-52266: The in-process Reports Server rep_wls_reports_oracle-forms failed to start.
REP-56105: Engine rwEng-0 died with error
SecurityHelper:start Writeable folders not configured. Output destination to 'File' will fail.
```

## Root Cause Analysis

The core issue is **SECURITY CONFIGURATION** for writeable folders. Despite:
- Modifying rwserver.conf manually
- Running WLST configuration script
- Creating cache directories with proper permissions

The Reports Server runtime is **NOT loading the security configuration** that allows writing to cache directories.

## Configuration Files Checked

### rwserver.conf Location
```
/u01/app/oracle/config/domains/forms_domain/config/fmwconfig/servers/WLS_REPORTS/applications/reports_14.1.2/configuration/rwserver.conf
```

**Current Content** (security section):
```xml
<security id="rwJaznSec" class="oracle.reports.server.RWJAZNSecurity">
   <property name="writeableFolders" value="/u01/app/oracle/config/domains/forms_domain/reports/cache;/tmp;/u01/app/oracle/reports_source"/>
</security>
```

### Problem
This configuration is **IN THE FILE** but **NOT BEING APPLIED** at runtime.

## What We've Tried

1. ✅ Increased JVM memory (helps overall but not the root issue)
2. ✅ Created cache directories with proper permissions
3. ✅ Modified rwserver.conf to add security configuration
4. ✅ Ran `ohs_updateInstances()` via WLST
5. ✅ Created Reports Tools instance via WLST
6. ✅ Restarted Reports Server multiple times
7. ❌ **Security configuration still not applied**

## Why It's Not Working

In Oracle Reports 14c with WebLogic, the **runtime security configuration** is managed by:
- **JMX MBeans** (Java Management Extensions)
- **Enterprise Manager Console**
- **OPSS** (Oracle Platform Security Services)

Simply editing the XML configuration file is **NOT sufficient**. The changes must be:
1. Registered in the WebLogic MBean Server
2. Persisted in the OPSS policy store
3. Loaded by the Reports Server at startup

## What Needs to Be Done

### Option 1: Enterprise Manager Console (Recommended)

1. Access EM Console:
   ```
   http://localhost:7001/em
   Username: weblogic
   Password: Oracle123
   ```

2. Navigate to Reports Server:
   - WebLogic Domain → forms_domain
   - **Right-click "reports"** → **System MBean Browser**
   - Browse to: **Application Defined MBeans** → **oracle.reports.serverconfig**

3. Configure Security MBean:
   - Find the Reports Server MBean node
   - Look for **Security** or **ServerConfig** MBean
   - Set property: `writeableFolders` = `/u01/app/oracle/config/domains/forms_domain/reports/cache;/tmp;/u01/app/oracle/reports_source`

4. Save and restart WLS_REPORTS

### Option 2: WLST Script (Advanced)

The WLST script needs to navigate to the **exact MBean path** for the running Reports Server and set the writeable folders property. The challenge is finding the correct MBean path, which varies by installation.

```python
# Pseudo-code - exact path needs to be discovered
cd('/oracle.reports.serverconfig/oracle.reports.server/rep_wls_reports_oracle-forms')
set('writeableFolders', '/path1;/path2;/path3')
```

### Option 3: Rebuild with Proper Configuration

Modify the Dockerfile/domain creation process to:
1. Create domain
2. Deploy Reports
3. Use WLST to configure security **before first startup**
4. Start servers with configuration in place

## Testing After Configuration

Once the security is properly configured, verify:

```bash
# Check logs for confirmation
docker exec oracle-forms-14c bash -c "grep -i 'writeable' /u01/app/oracle/config/domains/forms_domain/servers/WLS_REPORTS/logs/reports/rwserver_diagnostic.log | tail -5"

# Should NOT show: "Writeable folders not configured"

# Test report generation
curl "http://localhost:9002/reports/rwservlet?report=BLANK.rdf&destype=cache&DESFORMAT=html"
```

## Key Lessons Learned

1. **Oracle Reports 14c has strict security** - file system access must be explicitly configured
2. **XML configuration files alone are insufficient** - Must use MBeans/EM for runtime security
3. **The REP-1800 error is misleading** - It's a security/permission error, not a formatter error
4. **In-process server mode requires writeable folders** - Without it, the Reports Engine cannot start

## Recommended Next Action

**Use Oracle Enterprise Manager** to configure the writeable folders through the MBean browser. This is the officially supported method and will persist the configuration properly.

Alternative: If EM is not accessible, we need to discover the exact JMX MBean path for the Reports Server component and write a precise WLST script to set the security property.

## Reference Links

- Oracle Reports 14c Security Documentation
- WebLogic Server MBean Reference
- SimpleOracle Tutorial: https://simpleoracle.com/2019/11/08/install-oracle-forms-reports-12-2-1-4-with-weblogic-12c-12-2-1-4/
- Oracle Support Doc ID: 2118748.1 (REP-1800 Error Resolution)

---

**Summary**: Reports Server is running but cannot execute reports due to missing security configuration for writeable folders. The configuration must be set through Enterprise Manager or a properly targeted WLST script to take effect at runtime.
