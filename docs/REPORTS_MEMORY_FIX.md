# Oracle Reports REP-1800 Error - Memory Fix

## Problem
When accessing Oracle Reports via `http://localhost:9002/reports/rwservlet`, you encounter:
```
Error REP-1800: A formatter error occurred.
```

## Root Cause
The WebLogic Server managed servers (including reports_server1) were configured with only **512MB** heap memory in `setDomainEnv.sh`, which is insufficient for Oracle Reports operations, especially for:
- Large reports
- Reports with many images
- Complex report formatting

## Solution Applied

### Quick Fix (Already Applied to Running Container)
The memory settings in `setDomainEnv.sh` have been increased from:
```bash
WLS_MEM_ARGS_64BIT="-Xms512m -Xmx512m"
```

To:
```bash
WLS_MEM_ARGS_64BIT="-Xms1024m -Xmx2048m"
```

The container has been restarted to apply these changes.

## Permanent Solution (For Future Builds)

To make this fix permanent in your Docker image, modify the **Dockerfile**:

### Option 1: Modify setDomainEnv.sh during build

Add this to your Dockerfile after domain creation:

```dockerfile
# Increase memory for managed servers (especially Reports Server)
RUN sed -i 's/WLS_MEM_ARGS_64BIT="-Xms512m -Xmx512m"/WLS_MEM_ARGS_64BIT="-Xms1024m -Xmx2048m"/g' \
    /u01/app/oracle/config/domains/forms_domain/bin/setDomainEnv.sh && \
    sed -i 's/WLS_MEM_ARGS_32BIT="-Xms512m -Xmx512m"/WLS_MEM_ARGS_32BIT="-Xms1024m -Xmx2048m"/g' \
    /u01/app/oracle/config/domains/forms_domain/bin/setDomainEnv.sh && \
    sed -i 's/WLS_MEM_ARGS_64BIT="-Xms256m -Xmx512m"/WLS_MEM_ARGS_64BIT="-Xms1024m -Xmx2048m"/g' \
    /u01/app/oracle/config/domains/forms_domain/bin/setDomainEnv.sh && \
    sed -i 's/WLS_MEM_ARGS_32BIT="-Xms256m -Xmx512m"/WLS_MEM_ARGS_32BIT="-Xms1024m -Xmx2048m"/g' \
    /u01/app/oracle/config/domains/forms_domain/bin/setDomainEnv.sh
```

### Option 2: Set USER_MEM_ARGS Environment Variable

Add to your `docker-compose.yml` or startup script:

```yaml
environment:
  - USER_MEM_ARGS=-Xms1024m -Xmx2048m -XX:MaxPermSize=512m
```

### Option 3: Modify Startup Script

Create a custom startup script that sets memory before starting servers:

```bash
export USER_MEM_ARGS="-Xms1024m -Xmx2048m -XX:MaxPermSize=512m"
/u01/app/oracle/config/domains/forms_domain/bin/startManagedWebLogic.sh reports_server1
```

## Verification

After applying the fix, verify the Reports Server is running with increased memory:

```bash
# Check if Reports Server is responding
curl http://localhost:9002/reports/rwservlet

# Check the Java process memory settings
docker exec oracle-forms-14c bash -c "ps aux | grep reports_server1 | grep -o 'Xmx[^ ]*'"
```

You should see: `-Xmx2048m`

## Testing Your Report

Try accessing your report again:
```
http://localhost:9002/reports/rwservlet?cbslamconn&report=BLANK.rdf&destype=cache&DESFORMAT=html
```

## Additional Tuning (If Still Experiencing Issues)

If you still encounter memory issues with very large reports, you can further increase memory:

1. **For extremely large reports**: Increase to 4GB
   ```bash
   WLS_MEM_ARGS_64BIT="-Xms2048m -Xmx4096m"
   ```

2. **Adjust docker-compose.yml memory limits** to accommodate the JVM:
   ```yaml
   deploy:
     resources:
       limits:
         memory: 6G  # Increased from 4G
         cpus: '2.0'
   ```

3. **Optimize report design**:
   - Reduce image sizes
   - Use pagination for large datasets
   - Consider PDF output instead of HTML for better memory usage

## Troubleshooting

### Container won't start after memory increase
- Check that your host machine has enough memory
- Verify docker-compose.yml memory limits are sufficient
- Review container logs: `docker logs oracle-forms-14c`

### Reports still failing
1. Check Reports Server logs:
   ```bash
   docker exec oracle-forms-14c cat /u01/app/oracle/product/fmw14.1.2.0/user_projects/domains/forms_domain/servers/reports_server1/logs/reports_server1.log
   ```

2. Verify temp directory has space:
   ```bash
   docker exec oracle-forms-14c df -h /tmp
   ```

3. Check if report file exists and is accessible:
   ```bash
   docker exec oracle-forms-14c ls -la /u01/app/oracle/reports_source/BLANK.rdf
   ```

## References
- Oracle Support Doc: REP-1800 Error Solutions
- WebLogic Server Memory Configuration Guide
- Oracle Reports 14c Performance Tuning Guide
