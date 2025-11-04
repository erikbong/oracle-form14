# Oracle Forms & Reports 14c - Deployment Comparison

## Overview

This repository now contains **three deployment options** for Oracle Forms & Reports 14c:

1. **Automated Installation** (docker-compose.yml)
2. **Manual Installation** (docker-compose.manual.yml)
3. **Production Deployment** (docker-compose.production.yml) ⭐ NEW

---

## Deployment Options Comparison

| Feature | Automated | Manual | Production |
|---------|-----------|--------|------------|
| **Oracle Installation** | Installer runs during build | Manual install via VNC | Baked into image |
| **Build Time** | 30-40 minutes | 5 minutes (base image) | 15-20 minutes |
| **Installation Method** | Silent install scripts | GUI installers in VNC | Copy from ./Oracle/ |
| **Container Size** | ~8GB | ~2GB (base) | ~10GB |
| **Oracle Data Location** | Inside container | Host ./Oracle/ directory | Baked in image |
| **First Startup Time** | 5 minutes | 3 minutes (VNC only) | 5 minutes |
| **Subsequent Startup** | 5 minutes | 3-5 minutes | 3-5 minutes |
| **Configuration** | Response files | Manual GUI | External mount |
| **Database Included** | Yes (oracle-db) | No | Yes (oracle-db) |
| **VNC Access** | Yes (port 5901) | Yes (port 5901) | Yes (port 5901) |
| **Auto-Start Services** | No | Yes ✅ | Yes ✅ |
| **Portability** | Image is portable | Requires ./Oracle/ | Image is portable |
| **Best For** | Learning, testing | Development | Production, distribution |
| **Customization** | Rebuild required | Direct file editing | Config mounting |

---

## Detailed Comparison

### 1. Automated Installation (docker-compose.yml)

**Files:**
- `docker-compose.yml`
- `Dockerfile`
- `scripts/` - Installation scripts
- `response/` - Silent install response files

**Characteristics:**
- ✅ Fully automated - no manual steps
- ✅ Includes Oracle DB container
- ✅ Reproducible builds
- ❌ Long build time (30-40 minutes)
- ❌ Requires installation files in ./install/
- ❌ No auto-start (services must be started manually)

**Use Case:**
- Learning Oracle Forms & Reports
- Testing automated deployment
- CI/CD pipelines (if you have Oracle installer files)

**Quick Start:**
```bash
# Place installer files in ./install/
docker-compose up -d
```

---

### 2. Manual Installation (docker-compose.manual.yml)

**Files:**
- `docker-compose.manual.yml`
- `Dockerfile.manual`
- `entrypoint.sh`
- `.env.manual` or `.env`

**Characteristics:**
- ✅ Fast initial build (5 minutes)
- ✅ VNC GUI access for installation
- ✅ Full control over installation process
- ✅ Auto-start services ✅
- ✅ Oracle installation persists in ./Oracle/
- ✅ Easy to modify configurations
- ❌ Requires manual installation steps
- ❌ No database included (must add separately)
- ❌ Large ./Oracle/ directory on host

**Use Case:**
- Development environment
- Custom installation requirements
- Learning Oracle installation process
- Need to modify Oracle configurations frequently

**Quick Start:**
```bash
# Build and start
docker-compose -f docker-compose.manual.yml up -d

# Connect via VNC
vnc://localhost:5901

# Install Oracle manually (one time)
# After installation, services auto-start on restart
```

---

### 3. Production Deployment (docker-compose.production.yml) ⭐

**Files:**
- `docker-compose.production.yml`
- `Dockerfile.production`
- `entrypoint.sh`
- `.env.production`
- `config/` - External configuration directory

**Characteristics:**
- ✅ Oracle installation baked into image
- ✅ Includes Oracle DB container
- ✅ Auto-start services ✅
- ✅ External config mounting
- ✅ Production-ready (health checks, logging, resource limits)
- ✅ Portable - self-contained image
- ✅ Fast startup (3-5 minutes)
- ❌ Large image size (~10GB)
- ❌ Requires successful ./Oracle/ directory from manual setup
- ❌ Rebuild needed if Oracle installation changes

**Use Case:**
- Production deployment
- Distributing pre-configured image
- Multiple environments (dev, staging, prod)
- Kubernetes/cloud deployment
- When you need a complete, ready-to-run image

**Quick Start:**
```bash
# Prerequisites: ./Oracle/ directory from manual installation
cp .env.production .env

# Build production image
docker-compose -f docker-compose.production.yml build

# Start all services
docker-compose -f docker-compose.production.yml up -d

# Monitor startup
docker logs -f oracle-forms-production
```

---

## Migration Path

### From Manual to Production

If you've completed manual installation and want to create a production image:

```bash
# 1. Ensure manual installation is working
docker-compose -f docker-compose.manual.yml up -d
# ... verify all services work ...

# 2. Stop manual container
docker-compose -f docker-compose.manual.yml down

# 3. Build production image (copies ./Oracle/ into image)
docker-compose -f docker-compose.production.yml build

# 4. Start production setup
docker-compose -f docker-compose.production.yml up -d
```

### From Automated to Production

If you've used automated installation:

```bash
# 1. Copy Oracle installation from container to host
docker cp oracle-forms-14c:/u01/app/oracle/product/fmw14.1.2.0 ./Oracle/fmw
docker cp oracle-forms-14c:/u01/app/oracle/product/jdk17 ./Oracle/jdk17
docker cp oracle-forms-14c:/u01/app/oracle/config/domains ./Oracle/domains

# 2. Build production image
docker-compose -f docker-compose.production.yml build

# 3. Start production setup
docker-compose -f docker-compose.production.yml up -d
```

---

## Which Deployment Should You Use?

### Choose **Automated** if:
- ❓ You're learning Oracle Forms & Reports
- ❓ You want fully automated installation
- ❓ You have Oracle installer files
- ❓ You don't mind long build times

### Choose **Manual** if:
- ✋ You're actively developing
- ✋ You need GUI installation control
- ✋ You want to modify Oracle configurations frequently
- ✋ You have custom installation requirements
- ✋ You're learning the Oracle installation process

### Choose **Production** if:
- 🚀 You're deploying to production
- 🚀 You want a portable, self-contained image
- 🚀 You've completed manual installation successfully
- 🚀 You want to distribute a ready-to-run image
- 🚀 You need multiple identical environments
- 🚀 You're deploying to cloud/Kubernetes

---

## Configuration Management Comparison

### Automated
**Configuration:** Response files (`response/`)
**Changes:** Modify response files, rebuild image
**Persistence:** Inside container (lost on container removal)

### Manual
**Configuration:** Direct file editing in `./Oracle/`
**Changes:** Edit files in `./Oracle/`, restart container
**Persistence:** Host directory `./Oracle/` (persists)

### Production
**Configuration:** External mounts in `./config/`
**Changes:** Edit files in `./config/`, restart container
**Persistence:** Oracle in image (immutable), configs on host (mutable)

---

## Resource Requirements

| Deployment | RAM Required | Disk Space | Build Time | Startup Time |
|------------|-------------|------------|------------|--------------|
| Automated  | 8GB min, 12GB recommended | 30GB | 30-40 min | 5 min |
| Manual     | 8GB min, 12GB recommended | 25GB (with ./Oracle/) | 5 min | 3-5 min |
| Production | 8GB min, 12GB recommended | 50GB (image + DB) | 15-20 min | 3-5 min |

---

## Port Mappings (All Deployments)

| Service | Port | Protocol | Description |
|---------|------|----------|-------------|
| VNC | 5901 | VNC | Remote desktop access |
| WebLogic Admin | 7001 | HTTP | Admin console, EM |
| Forms | 9001 | HTTP | Forms servlet |
| Reports | 9002 | HTTP | Reports servlet (→9012) |
| WebLogic | 5556, 5557 | TCP | Additional WLS ports |
| Oracle DB | 1521 | TCP | Database listener |

---

## Conclusion

- **Manual** setup is great for development and learning
- **Production** setup is ideal for deployment after manual setup is working
- **Automated** setup is good for CI/CD if you have installer files

**Recommended Path:**
1. Start with **Manual** setup to learn and configure
2. Verify everything works correctly
3. Build **Production** image from your working ./Oracle/ directory
4. Deploy production image to staging/production environments

---

## Next Steps

### If using Manual (Development):
- See [MANUAL_INSTALLATION_GUIDE.md](MANUAL_INSTALLATION_GUIDE.md)
- See [AUTO_START_GUIDE.md](AUTO_START_GUIDE.md)

### If using Production (Deployment):
- See [PRODUCTION_GUIDE.md](PRODUCTION_GUIDE.md)
- Review `.env.production` settings
- Customize `./config/` files as needed

### Backup and Recovery:
- See [BACKUP_GUIDE.md](BACKUP_GUIDE.md)
- Create regular backups before changes
- Test restore procedures

---

**Your Oracle Forms & Reports 14c deployment is ready!** 🎉
