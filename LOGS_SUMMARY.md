# Oracle Reports Server Logs Summary

## Status: Writeable Folders Issue FIXED ✅

### Timeline of Events

**Before 08:01:58 (Nov 3)**
- Error: "Writeable folders not configured. Output destination to 'File' will fail"
- Reports Engine crashes immediately on startup

**After 08:01:58 (Nov 3)** - After adding `<folderAccess>` configuration
- ✅ NO MORE "Writeable folders not configured" error
- ✅ Configuration loaded successfully with folderAccess
- ❌ Engine still crashes, but for a DIFFERENT reason

### Key Log Entries

**Configuration Successfully Loaded (08:01:58):**
```
[2025-11-03T08:01:58.285] ServerConfig:logConf  Reading server config file
<folderAccess>
  <write>/u01/app/oracle/config/domains/forms_domain/reports/cache</write>
  <write>/tmp</write>
  <write>/u01/app/oracle/reports_source</write>
</folderAccess>
```

**Engine Crash (08:02 onwards):**
```
[2025-11-03T08:02:01.779] EngineManager:manage  Engine rwEng-0 died with error: {1}.
[2025-11-03T08:02:01.983] EngineManager:manage  Engine rwEng-0 died with error: {1}.
[2025-11-03T08:02:02.189] REP-56105 : Engine rwEng-0 died with error: .
```

**Note:** The error detail `{1}` is not being filled in - this is a logging issue where the actual error is not captured.

### Current Issue

The engine (rwEng-0) starts but crashes immediately with NO error details logged. Possible causes:

1. **Database connection issue** - The test report `cbslamconn` might have database connection problems
2. **Missing libraries** - Some required shared libraries for the engine might be missing
3. **JVM/CORBA configuration** - Engine uses CORBA for communication, might have initialization issues
4. **File permissions** - Even though folderAccess is configured, there might be OS-level permission issues

### Files Copied to Root Folder

- `rwserver_diagnostic.log` - Reports Server main log
- `rwEng-0_diagnostic.log` - Reports Engine log (OLD entries from Nov 1st only)
- `rwservlet_diagnostic.log` - Reports Servlet log

### Configuration is PERMANENT ✅

The rwserver.conf file with folderAccess is stored in Docker volume `oracle_domain_data` and will persist across container restarts.

Path: `/u01/app/oracle/config/domains/forms_domain/config/fmwconfig/servers/WLS_REPORTS/applications/reports_14.1.2/configuration/rwserver.conf`

### Next Steps

1. Try running a simpler report without database connection to isolate the issue
2. Check if there are missing library dependencies for the engine
3. Review Java/CORBA configuration for the Reports Engine
4. Check OS-level file permissions on cache directories
