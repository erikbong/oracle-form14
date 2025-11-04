# Production Deployment Checklist

Use this checklist to ensure your production deployment is ready.

---

## ✅ Pre-Build Checklist

Before building the production image:

### 1. Verify Manual Installation
- [ ] Manual container is running: `docker ps | grep oracle-forms-manual`
- [ ] All services are working (AdminServer, WLS_FORMS, WLS_REPORTS)
- [ ] Can access WebLogic Console: http://localhost:7001/console
- [ ] Can access Forms: http://localhost:9001/forms/frmservlet
- [ ] Can access Reports: http://localhost:9002/reports/rwservlet

### 2. Verify Oracle Directory
- [ ] `./Oracle/` directory exists
- [ ] `./Oracle/jdk17/` exists and contains Java installation
- [ ] `./Oracle/fmw/` exists and contains Oracle Home
- [ ] `./Oracle/fmw/user_projects/domains/base_domain/` exists
- [ ] Startup scripts exist: `./Oracle/startAllServices.sh`, `./Oracle/stopAllServices.sh`

### 3. Check Directory Structure
```bash
# Run this to verify structure
ls -la ./Oracle/
ls -la ./Oracle/jdk17/
ls -la ./Oracle/fmw/
ls -la ./Oracle/fmw/user_projects/domains/base_domain/
```

### 4. Stop Manual Container
- [ ] Gracefully stop services: `docker exec -u oracle oracle-forms-manual-install /u01/app/oracle/middleware/stopAllServices.sh`
- [ ] Stop container: `docker-compose -f docker-compose.manual.yml down`

---

## ✅ Build Checklist

### 1. Environment Configuration
- [ ] Copy `.env.production` to `.env`: `cp .env.production .env`
- [ ] Review `.env` settings
- [ ] **IMPORTANT:** Change default passwords:
  - [ ] `WLS_PW` (WebLogic admin password)
  - [ ] `DB_PASSWORD` (Database sys password)
  - [ ] `DB_APP_PASSWORD` (RCU user password)
  - [ ] `VNC_PASSWORD` (VNC access password)

### 2. Resource Settings
- [ ] Set memory limits (`MEM_LIMIT`, `MEM_RESERVATION`)
- [ ] Set CPU limits (`CPUS`)
- [ ] Set shared memory (`SHM_SIZE`)
- [ ] Verify host has enough resources (recommended: 16GB RAM, 50GB disk)

### 3. Port Configuration
- [ ] Verify ports are not in use:
  ```bash
  netstat -an | grep "7001\|9001\|9002\|1521\|5901"
  ```
- [ ] Change ports in `.env` if conflicts exist

### 4. Build Production Image
- [ ] Run build command:
  ```bash
  docker-compose -f docker-compose.production.yml build
  ```
- [ ] Wait 15-20 minutes for build to complete
- [ ] Verify image was created:
  ```bash
  docker images | grep oracle-forms-14c-production
  ```

---

## ✅ Deployment Checklist

### 1. Start Services
- [ ] Start containers:
  ```bash
  docker-compose -f docker-compose.production.yml up -d
  ```
- [ ] Verify containers are running:
  ```bash
  docker ps | grep -E "oracle-forms-production|oracle-db-production"
  ```

### 2. Monitor Startup
- [ ] Watch logs for Forms/Reports:
  ```bash
  docker logs -f oracle-forms-production
  ```
- [ ] Wait for messages:
  - [ ] "Starting VNC server..."
  - [ ] "Auto-starting Oracle services..."
  - [ ] "Starting NodeManager..."
  - [ ] "Starting AdminServer..."
  - [ ] "Starting WLS_FORMS..."
  - [ ] "Starting WLS_REPORTS..."

### 3. Verify Database
- [ ] Database container is healthy:
  ```bash
  docker ps | grep oracle-db-production
  ```
- [ ] Database is ready (look for "healthy" status)
- [ ] Test connection:
  ```bash
  docker exec oracle-db-production healthcheck.sh
  ```

### 4. Wait for Services (3-5 minutes)
- [ ] NodeManager started
- [ ] AdminServer started (check logs for "RUNNING")
- [ ] WLS_FORMS started (check logs for "RUNNING")
- [ ] WLS_REPORTS started (check logs for "RUNNING")

---

## ✅ Verification Checklist

### 1. Service Access
- [ ] VNC: `vnc://localhost:5901` (password from .env)
- [ ] WebLogic Console: http://localhost:7001/console
  - [ ] Can login with credentials from .env
  - [ ] Servers show as "RUNNING" in console
- [ ] Enterprise Manager: http://localhost:7001/em
- [ ] Forms: http://localhost:9001/forms/frmservlet
- [ ] Reports: http://localhost:9002/reports/rwservlet

### 2. Check Running Processes
```bash
# Should show 4 processes: NodeManager, AdminServer, WLS_FORMS, WLS_REPORTS
docker exec -u oracle oracle-forms-production ps aux | grep weblogic
```

- [ ] NodeManager process is running
- [ ] AdminServer process is running
- [ ] WLS_FORMS process is running
- [ ] WLS_REPORTS process is running

### 3. Health Checks
```bash
# Check health status
docker ps --format "table {{.Names}}\t{{.Status}}"
```

- [ ] oracle-forms-production shows "healthy"
- [ ] oracle-db-production shows "healthy"

### 4. Network Connectivity
```bash
# Test Forms/Reports can connect to database
docker exec -u oracle oracle-forms-production ping -c 2 oracle-db
```

- [ ] Forms container can reach database container
- [ ] Network `oracle-forms-network` exists

---

## ✅ Configuration Checklist

### 1. Configuration Directories
- [ ] `./config/forms/` exists
- [ ] `./config/reports/` exists
- [ ] `./config/tnsnames/` exists
- [ ] `./forms_source/` exists
- [ ] `./reports_source/` exists
- [ ] `./logs/` exists

### 2. TNS Configuration
- [ ] `./config/tnsnames/tnsnames.ora` exists
- [ ] Contains `FREEPDB1` entry
- [ ] Points to `oracle-db:1521`

### 3. Test Configuration Changes
- [ ] Edit a config file in `./config/`
- [ ] Restart container:
  ```bash
  docker-compose -f docker-compose.production.yml restart oracle-forms
  ```
- [ ] Verify change took effect

---

## ✅ Optional: Nginx Proxy

If using nginx reverse proxy:

- [ ] Start with proxy profile:
  ```bash
  docker-compose -f docker-compose.production.yml --profile proxy up -d
  ```
- [ ] Nginx container is running
- [ ] Can access via proxy:
  - [ ] http://localhost:8880/console
  - [ ] http://localhost:8880/forms
  - [ ] http://localhost:8880/reports

---

## ✅ Production Readiness

### Security
- [ ] Changed all default passwords
- [ ] Reviewed security settings in WebLogic Console
- [ ] Disabled development mode (if applicable)
- [ ] Configured SSL/TLS (if needed)
- [ ] Firewall rules configured (if applicable)

### Backup
- [ ] Backup production image:
  ```bash
  docker save oracle-forms-14c-production:latest | gzip > oracle-forms-production.tar.gz
  ```
- [ ] Backup configuration files:
  ```bash
  tar -czf config-backup.tar.gz ./config ./forms_source ./reports_source
  ```
- [ ] Backup database (if needed):
  ```bash
  docker exec oracle-db-production sh -c 'expdp rcu_user/PASSWORD@FREEPDB1 full=y directory=DATA_PUMP_DIR dumpfile=backup.dmp'
  ```

### Monitoring
- [ ] Set up log monitoring
- [ ] Configure alerts for container health
- [ ] Set up resource monitoring (CPU, memory, disk)
- [ ] Configure backup schedule

### Documentation
- [ ] Document deployment steps
- [ ] Document custom configurations
- [ ] Document access credentials (securely)
- [ ] Document backup/restore procedures
- [ ] Document rollback procedures

---

## ✅ Testing Checklist

### Functional Testing
- [ ] Deploy a test Forms application (.fmb)
- [ ] Deploy a test Reports application (.rdf)
- [ ] Test Forms application in web browser
- [ ] Test Reports servlet
- [ ] Test database connectivity from Forms/Reports

### Performance Testing
- [ ] Monitor resource usage under load
- [ ] Test concurrent user access
- [ ] Check response times
- [ ] Verify no memory leaks

### Recovery Testing
- [ ] Stop containers and restart
- [ ] Verify auto-start works
- [ ] Test backup restoration
- [ ] Verify data persistence

---

## ✅ Go-Live Checklist

### Pre-Go-Live
- [ ] All functional tests passed
- [ ] All performance tests passed
- [ ] All security requirements met
- [ ] Backups tested and working
- [ ] Monitoring in place
- [ ] Documentation complete
- [ ] Rollback plan prepared

### Go-Live
- [ ] Deploy to production environment
- [ ] Verify all services started
- [ ] Run smoke tests
- [ ] Monitor logs for errors
- [ ] Verify user access

### Post-Go-Live
- [ ] Monitor for 24 hours
- [ ] Check logs daily for first week
- [ ] Verify backups running
- [ ] Document any issues
- [ ] Collect user feedback

---

## 🎉 Deployment Complete!

If all checkboxes are checked, your production deployment is ready!

### Quick Reference Commands

**Start services:**
```bash
docker-compose -f docker-compose.production.yml up -d
```

**Stop services:**
```bash
docker-compose -f docker-compose.production.yml down
```

**View logs:**
```bash
docker logs -f oracle-forms-production
```

**Restart services:**
```bash
docker-compose -f docker-compose.production.yml restart
```

**Check status:**
```bash
docker ps
docker-compose -f docker-compose.production.yml ps
```

---

## 📚 Additional Resources

- [PRODUCTION_GUIDE.md](PRODUCTION_GUIDE.md) - Complete production guide
- [DEPLOYMENT_COMPARISON.md](DEPLOYMENT_COMPARISON.md) - Compare deployments
- [BACKUP_GUIDE.md](BACKUP_GUIDE.md) - Backup procedures
- [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) - Troubleshooting guide

---

**Need help?** See [PRODUCTION_GUIDE.md](PRODUCTION_GUIDE.md) for detailed instructions.
