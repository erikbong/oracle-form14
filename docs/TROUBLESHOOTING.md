# Oracle Forms & Reports 14c Troubleshooting Guide

This guide provides solutions to common issues you may encounter when deploying Oracle Forms & Reports 14c with Docker.

## Table of Contents

- [Quick Diagnostics](#quick-diagnostics)
- [Build Issues](#build-issues)
- [Runtime Issues](#runtime-issues)
- [Performance Issues](#performance-issues)
- [Network and Access Issues](#network-and-access-issues)
- [Data and Storage Issues](#data-and-storage-issues)
- [Advanced Debugging](#advanced-debugging)
- [Getting Help](#getting-help)

## Quick Diagnostics

### Health Check Commands

```bash
# Check all services status
docker-compose ps

# Check container health
docker-compose exec oracle-forms curl -f http://localhost:7001/console

# Check logs for errors
docker-compose logs --tail=50 oracle-forms

# Check system resources
docker stats --no-stream

# Check Docker daemon status
docker info
```

### Common Status Indicators

| Status | Description | Action |
|--------|-------------|--------|
| `Up (healthy)` | Service running normally | ✅ No action needed |
| `Up (unhealthy)` | Service running but health check fails | Check logs |
| `Exited (0)` | Clean shutdown | Restart if unexpected |
| `Exited (137)` | Killed by OOM | Increase memory |
| `Restarting` | Crash loop | Check logs immediately |

## Build Issues

### Issue: Docker Build Fails to Start

**Symptoms:**
```
Error response from daemon: Cannot connect to the Docker daemon
```

**Solutions:**
1. **Start Docker Desktop/Engine:**
   ```bash
   # Windows/Mac: Start Docker Desktop application
   # Linux:
   sudo systemctl start docker
   sudo systemctl enable docker
   ```

2. **Check Docker installation:**
   ```bash
   docker --version
   docker-compose --version
   ```

### Issue: Package Installation Fails

**Symptoms:**
```
Failed to download packages
Package not found
microdnf: error
```

**Solutions:**
1. **Check internet connectivity:**
   ```bash
   docker run --rm alpine ping -c 3 google.com
   ```

2. **Clear Docker cache and retry:**
   ```bash
   docker system prune -a
   docker-compose build --no-cache
   ```

3. **Configure proxy if needed:**
   ```dockerfile
   # Add to Dockerfile if behind corporate proxy
   ENV HTTP_PROXY=http://proxy.company.com:8080
   ENV HTTPS_PROXY=http://proxy.company.com:8080
   ```

### Issue: Oracle Installation Files Not Found

**Symptoms:**
```
COPY failed: stat install/fmw_14.1.2.0.0_infrastructure.jar: no such file
```

**Solutions:**
1. **Verify files exist:**
   ```bash
   ls -la install/
   # Should show all three Oracle files
   ```

2. **Check file permissions:**
   ```bash
   chmod 644 install/*
   ```

3. **Verify exact filenames:**
   ```bash
   # Required files (case-sensitive):
   # jdk-17.0.12_linux-x64_bin.tar.gz
   # fmw_14.1.2.0.0_infrastructure.jar
   # fmw_14.1.2.0.0_fr_linux64.bin
   ```

### Issue: Oracle Installation Fails

**Symptoms:**
```
oracle_common directory NOT found - installation failed
The installation of Oracle Fusion Middleware 14.1.2 Infrastructure failed
```

**Solutions:**
1. **Check installation logs:**
   ```bash
   # Build with more verbose output
   docker-compose build --no-cache --progress=plain
   ```

2. **Verify Oracle files integrity:**
   ```bash
   # Check file sizes
   ls -lh install/
   # infrastructure.jar should be ~2.1GB
   # fr_linux64.bin should be ~1.3GB
   ```

3. **Check available disk space:**
   ```bash
   df -h
   # Need at least 20GB free for build
   ```

4. **Try manual installation test:**
   ```bash
   # Test Oracle installer manually
   docker run --rm -v $(pwd)/install:/install oracle/linux:8-slim \
     java -jar /install/fmw_14.1.2.0.0_infrastructure.jar -help
   ```

### Issue: Domain Creation Fails

**Symptoms:**
```
WLST Exception: Could not create generic operation:Server
forms_domain directory not found
```

**Solutions:**
1. **Check WLST script syntax:**
   ```bash
   # Review createDomain.py for errors
   cat scripts/createDomain.py
   ```

2. **Test WLST manually:**
   ```bash
   docker run --rm -v $(pwd)/scripts:/scripts oracle-forms-14c \
     /u01/app/oracle/product/fmw14.1.2.0/oracle_common/common/bin/wlst.sh /scripts/createDomain.py
   ```

3. **Check user permissions:**
   ```bash
   # Ensure oracle user can write to domain directory
   docker run --rm oracle-forms-14c ls -la /u01/app/oracle/config/
   ```

## Runtime Issues

### Issue: Container Exits Immediately

**Symptoms:**
```bash
docker-compose ps
# Shows: Exited (1) or Exited (137)
```

**Diagnostic Steps:**
```bash
# Check exit reason
docker-compose logs oracle-forms

# Check startup script
docker-compose exec oracle-forms cat /scripts/startAll.sh

# Test startup manually
docker-compose exec oracle-forms bash
cd /u01/app/oracle/config/domains/forms_domain
./bin/startWebLogic.sh
```

**Common Solutions:**

1. **Exit Code 137 (OOM Kill):**
   ```bash
   # Increase Docker memory allocation
   # Docker Desktop: Settings → Resources → Memory → 8GB+

   # Or reduce JVM heap size
   # .env file:
   JAVA_OPTIONS=-Xmx1536m -Xms1024m
   ```

2. **Exit Code 1 (General Error):**
   ```bash
   # Check logs for specific error
   docker-compose logs oracle-forms | tail -50

   # Common issues:
   # - Port already in use
   # - Domain corruption
   # - Permission issues
   ```

3. **Permission Issues:**
   ```bash
   # Fix ownership
   docker-compose exec --user root oracle-forms \
     chown -R oracle:oinstall /u01/app/oracle/config
   ```

### Issue: Services Won't Start

**Symptoms:**
```
AdminServer failed to start
forms_server1 is not responding
```

**Solutions:**

1. **Check WebLogic processes:**
   ```bash
   docker-compose exec oracle-forms ps aux | grep java
   ```

2. **Start services manually:**
   ```bash
   docker-compose exec oracle-forms bash
   cd /u01/app/oracle/config/domains/forms_domain

   # Start AdminServer
   nohup ./bin/startWebLogic.sh &

   # Wait for AdminServer, then start managed servers
   nohup ./bin/startManagedWebLogic.sh forms_server1 &
   nohup ./bin/startManagedWebLogic.sh reports_server1 &
   ```

3. **Check domain configuration:**
   ```bash
   # Verify domain files
   docker-compose exec oracle-forms ls -la /u01/app/oracle/config/domains/forms_domain/

   # Check domain validity
   docker-compose exec oracle-forms \
     /u01/app/oracle/product/fmw14.1.2.0/oracle_common/common/bin/wlst.sh \
     -c "readDomain('/u01/app/oracle/config/domains/forms_domain')"
   ```

### Issue: Long Startup Times

**Symptoms:**
- Container takes >5 minutes to become healthy
- Services timeout during startup

**Solutions:**

1. **Adjust startup timeouts:**
   ```yaml
   # docker-compose.override.yml
   services:
     oracle-forms:
       healthcheck:
         start_period: 600s  # 10 minutes
         interval: 30s
   ```

2. **Optimize JVM startup:**
   ```bash
   # .env file
   JAVA_OPTIONS=-Xmx2048m -Xms2048m -XX:+UseG1GC -XX:+UnlockExperimentalVMOptions
   ```

3. **Check system resources:**
   ```bash
   # Monitor during startup
   docker stats oracle-forms-14c
   ```

## Performance Issues

### Issue: High Memory Usage

**Symptoms:**
```
Container using >6GB RAM
System becoming unresponsive
```

**Solutions:**

1. **Optimize JVM settings:**
   ```bash
   # .env file - Conservative settings
   JAVA_OPTIONS=-Xmx2048m -Xms1024m -XX:+UseG1GC -XX:MaxGCPauseMillis=200
   ```

2. **Set container limits:**
   ```yaml
   # docker-compose.override.yml
   services:
     oracle-forms:
       deploy:
         resources:
           limits:
             memory: 4G
           reservations:
             memory: 2G
   ```

3. **Monitor memory usage:**
   ```bash
   # Check JVM memory
   docker-compose exec oracle-forms \
     jps -v | grep java

   # Check container memory
   docker stats --format "table {{.Container}}\t{{.MemUsage}}\t{{.MemPerc}}"
   ```

### Issue: High CPU Usage

**Symptoms:**
```
Container using >80% CPU constantly
Host system slow
```

**Solutions:**

1. **Limit CPU usage:**
   ```yaml
   # docker-compose.override.yml
   services:
     oracle-forms:
       deploy:
         resources:
           limits:
             cpus: '2.0'
   ```

2. **Optimize garbage collection:**
   ```bash
   # .env file
   JAVA_OPTIONS=-Xmx2048m -XX:+UseG1GC -XX:MaxGCPauseMillis=200 -XX:G1HeapRegionSize=16m
   ```

3. **Check for infinite loops:**
   ```bash
   # Monitor Java threads
   docker-compose exec oracle-forms \
     jstack $(pgrep java)
   ```

### Issue: Slow Response Times

**Symptoms:**
- WebLogic console loads slowly
- Applications timeout
- Long page load times

**Solutions:**

1. **Increase connection pools:**
   - Access WebLogic Console → Services → Data Sources
   - Increase Initial Capacity and Maximum Capacity

2. **Optimize startup classes:**
   ```bash
   # Disable unnecessary startup classes in WebLogic Console
   # Domain → Environment → Startup & Shutdown Classes
   ```

3. **Enable compression:**
   ```bash
   # In WebLogic Console:
   # Servers → AdminServer → Configuration → Web Server
   # Enable "Use HTTP Chunked Transfer-Encoding"
   ```

## Network and Access Issues

### Issue: Cannot Access WebLogic Console

**Symptoms:**
```
curl: (7) Failed to connect to localhost port 7001
Connection refused
```

**Diagnostic Steps:**
```bash
# Check if container is running
docker-compose ps

# Check if port is bound
docker port $(docker-compose ps -q oracle-forms)

# Check if service is listening inside container
docker-compose exec oracle-forms netstat -tlnp | grep 7001

# Test from inside container
docker-compose exec oracle-forms curl -f http://localhost:7001/console
```

**Solutions:**

1. **Port conflicts:**
   ```bash
   # Check what's using port 7001
   netstat -tlnp | grep 7001

   # Use different external port
   # .env file:
   EXTERNAL_ADMIN_PORT=8001
   ```

2. **Firewall issues:**
   ```bash
   # Windows: Allow Docker in Windows Firewall
   # Linux: Check iptables rules
   sudo iptables -L | grep 7001
   ```

3. **Service not started:**
   ```bash
   # Wait for full startup (2-3 minutes)
   # Or check startup logs
   docker-compose logs -f oracle-forms
   ```

### Issue: Nginx Proxy Not Working

**Symptoms:**
```
curl: (7) Failed to connect to localhost port 80
502 Bad Gateway
```

**Solutions:**

1. **Check nginx configuration:**
   ```bash
   # Test nginx config
   docker-compose exec nginx nginx -t

   # Check upstream connectivity
   docker-compose exec nginx curl -f http://oracle-forms:7001/console
   ```

2. **Verify network connectivity:**
   ```bash
   # Check if containers can communicate
   docker-compose exec nginx ping oracle-forms

   # Check network configuration
   docker network ls
   docker network inspect oracle-forms-network
   ```

3. **Check nginx logs:**
   ```bash
   docker-compose logs nginx
   ```

## Data and Storage Issues

### Issue: Data Not Persisting

**Symptoms:**
- Configuration lost after container restart
- Logs disappear
- Domain changes not saved

**Solutions:**

1. **Check volume mounts:**
   ```bash
   # List volumes
   docker volume ls | grep oracle

   # Inspect volume
   docker volume inspect oracle_domain_data
   ```

2. **Verify volume usage:**
   ```bash
   # Check if data is being written to volumes
   docker-compose exec oracle-forms ls -la /u01/app/oracle/config/domains/
   ```

3. **Fix volume permissions:**
   ```bash
   # Ensure oracle user owns data directories
   docker-compose exec --user root oracle-forms \
     chown -R oracle:oinstall /u01/app/oracle/config
   ```

### Issue: Disk Space Issues

**Symptoms:**
```
No space left on device
Write failed
```

**Solutions:**

1. **Check disk usage:**
   ```bash
   # Host disk space
   df -h

   # Docker disk usage
   docker system df

   # Container disk usage
   docker-compose exec oracle-forms df -h
   ```

2. **Clean up Docker:**
   ```bash
   # Remove unused containers, networks, images
   docker system prune -a

   # Remove unused volumes (BE CAREFUL!)
   docker volume prune
   ```

3. **Log rotation:**
   ```bash
   # Configure log rotation in docker-compose.yml
   logging:
     driver: "json-file"
     options:
       max-size: "100m"
       max-file: "3"
   ```

## Advanced Debugging

### Enable Debug Logging

1. **WebLogic Debug:**
   ```bash
   # .env file
   JAVA_OPTIONS=-Xmx2048m -Dweblogic.debug.DebugAll=true
   ```

2. **Container Debug:**
   ```bash
   # Run container in interactive mode
   docker-compose run --rm oracle-forms bash
   ```

### Memory Debugging

```bash
# Check JVM memory
docker-compose exec oracle-forms \
  jstat -gc $(pgrep java)

# Generate heap dump
docker-compose exec oracle-forms \
  jmap -dump:format=b,file=/tmp/heapdump.hprof $(pgrep java)

# Analyze with jhat (if available)
docker-compose exec oracle-forms \
  jhat /tmp/heapdump.hprof
```

### Network Debugging

```bash
# Check network connectivity
docker-compose exec oracle-forms ping google.com

# Check DNS resolution
docker-compose exec oracle-forms nslookup oracle-forms

# Check port connectivity
docker-compose exec oracle-forms telnet localhost 7001
```

### Performance Profiling

```bash
# Monitor Java processes
docker-compose exec oracle-forms \
  jps -v

# Monitor system calls
docker-compose exec oracle-forms \
  strace -p $(pgrep java)

# Monitor file access
docker-compose exec oracle-forms \
  lsof -p $(pgrep java)
```

## Getting Help

### Collecting Debug Information

When seeking help, collect this information:

```bash
# System information
uname -a
docker --version
docker-compose --version

# Container status
docker-compose ps
docker-compose logs --tail=100 oracle-forms

# Resource usage
docker stats --no-stream
free -h
df -h

# Configuration
cat .env
cat docker-compose.yml
```

### Support Resources

1. **Documentation:**
   - [README.md](README.md) - User guide
   - [INSTALLATION_GUIDE.md](INSTALLATION_GUIDE.md) - Setup instructions
   - [CLAUDE.md](CLAUDE.md) - Technical details

2. **Community Support:**
   - GitHub Issues: https://github.com/erikbong/oracle-form14/issues
   - Stack Overflow: Tag with `oracle-forms`, `docker`

3. **Oracle Documentation:**
   - Oracle Forms Documentation
   - WebLogic Server Documentation
   - Oracle Docker Best Practices

### Creating Bug Reports

Include this information:

- **Environment**: OS, Docker version, system specs
- **Steps to reproduce**: Exact commands used
- **Expected behavior**: What should happen
- **Actual behavior**: What actually happens
- **Logs**: Relevant container logs
- **Configuration**: .env file and any overrides

---

**Need immediate help?** Check our [GitHub Issues](https://github.com/erikbong/oracle-form14/issues) for known problems and solutions.