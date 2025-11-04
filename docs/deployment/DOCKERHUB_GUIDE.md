# Docker Hub Deployment Guide

This guide explains how to push your Oracle Forms & Reports production image to Docker Hub for easy distribution and deployment.

---

## Overview

**Deployment Architecture:**
- **Forms/Reports Image**: Your custom image (~10GB) - You build and push
- **Database Image**: Public `gvenzl/oracle-free:23-slim` - No push needed
- **Orchestration**: Docker Compose manages both containers

**Benefits:**
- ✅ Smaller image size (~10GB vs 20GB+)
- ✅ Faster uploads/downloads
- ✅ Can scale independently
- ✅ Production-ready architecture
- ✅ Database uses maintained public image

---

## Prerequisites

1. **Docker Hub Account**: Create at https://hub.docker.com
2. **Working Installation**: Complete manual installation with all services running
3. **Docker Login**: Be logged in to Docker Hub
4. **Disk Space**: 30GB+ free for building and pushing images

---

## Step 1: Build Production Image

First, ensure your manual installation is working perfectly.

```bash
# Verify manual installation is working
docker-compose -f docker-compose.manual.yml up -d
# Test all services...

# Stop manual container
docker-compose -f docker-compose.manual.yml down
```

Now build the production image:

```bash
# Copy production files from docs
cp docs/deployment/Dockerfile.production ./
cp docs/deployment/docker-compose.production.yml ./
cp docs/deployment/.env.production ./.env
cp docs/deployment/entrypoint.sh ./

# Set your Docker Hub username in .env
# Edit .env file:
# DOCKERHUB_USERNAME=your-dockerhub-username

# IMPORTANT: Change passwords in .env for production!
# - WLS_PW
# - DB_PASSWORD
# - VNC_PASSWORD

# Build the image (copies ./Oracle/ into image, takes 15-20 minutes)
docker-compose -f docker-compose.production.yml build
```

---

## Step 2: Tag for Docker Hub

```bash
# Set your Docker Hub username
export DOCKERHUB_USERNAME=your-dockerhub-username

# Or on Windows PowerShell:
$env:DOCKERHUB_USERNAME="your-dockerhub-username"

# Tag image for Docker Hub
docker tag oracle-forms-14c-production:latest ${DOCKERHUB_USERNAME}/oracle-forms-reports:latest
docker tag oracle-forms-14c-production:latest ${DOCKERHUB_USERNAME}/oracle-forms-reports:14c
docker tag oracle-forms-14c-production:latest ${DOCKERHUB_USERNAME}/oracle-forms-reports:14.1.2.0
```

**Tag Explanation:**
- `latest` - Most recent stable version (auto-updated)
- `14c` - Oracle Forms 14c version
- `14.1.2.0` - Specific version number

---

## Step 3: Login to Docker Hub

```bash
# Login to Docker Hub
docker login

# Enter your Docker Hub username and password
# Or use access token (recommended for security)
```

**Using Access Token (Recommended):**
1. Go to https://hub.docker.com/settings/security
2. Click "New Access Token"
3. Name: "oracle-forms-deployment"
4. Permissions: Read, Write, Delete
5. Copy the token
6. Use token as password when running `docker login`

---

## Step 4: Push to Docker Hub

```bash
# Push all tagged versions (this will take 30-60 minutes depending on upload speed)
docker push ${DOCKERHUB_USERNAME}/oracle-forms-reports:latest
docker push ${DOCKERHUB_USERNAME}/oracle-forms-reports:14c
docker push ${DOCKERHUB_USERNAME}/oracle-forms-reports:14.1.2.0

# Monitor upload progress
# You'll see layers being pushed and a progress bar
```

**Upload Time Estimates:**
- 10 Mbps upload: ~2 hours
- 50 Mbps upload: ~30 minutes
- 100 Mbps upload: ~15 minutes

---

## Step 5: Create docker-compose.hub.yml

Create a deployment file for others to use:

```yaml
version: '3.8'

services:
  oracle-db:
    image: gvenzl/oracle-free:23-slim
    container_name: oracle-db-production
    hostname: oracle-db
    ports:
      - "${DB_PORT:-1521}:1521"
    environment:
      - ORACLE_PASSWORD=${DB_PASSWORD:-Oracle123}
      - APP_USER=${DB_APP_USER:-rcu_user}
      - APP_USER_PASSWORD=${DB_APP_PASSWORD:-Oracle123}
    volumes:
      - oracle_db_data:/opt/oracle/oradata
    healthcheck:
      test: ["CMD", "healthcheck.sh"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 60s
    shm_size: ${DB_SHM_SIZE:-1gb}
    restart: unless-stopped
    networks:
      - oracle-forms-network

  oracle-forms:
    # Use image from Docker Hub instead of building
    image: ${DOCKERHUB_USERNAME}/oracle-forms-reports:latest
    container_name: oracle-forms-production
    hostname: oracle-forms

    ports:
      - "${VNC_PORT:-5901}:5901"
      - "${ADMIN_PORT:-7001}:7001"
      - "${FORMS_PORT:-9001}:9001"
      - "${REPORTS_PORT:-9002}:9012"
      - "${WLS_PORT1:-5556}:5556"
      - "${WLS_PORT2:-5557}:5557"

    volumes:
      - ./config/forms:/u01/app/oracle/middleware/config/forms:rw
      - ./forms_source:/home/oracle/forms_source:rw
      - ./config/reports:/u01/app/oracle/middleware/config/reports:rw
      - ./reports_source:/home/oracle/reports_source:rw
      - ./reports_temp:/home/oracle/reports_temp:rw
      - ./config/tnsnames:/u01/app/oracle/middleware/config/tnsnames:rw
      - ./logs:/u01/app/oracle/middleware/logs:rw

    environment:
      - DISPLAY=:1
      - VNC_RESOLUTION=${VNC_RESOLUTION:-1280x1024}
      - VNC_PASSWORD=${VNC_PASSWORD:-Oracle123}
      - ORACLE_BASE=/u01/app/oracle
      - ORACLE_HOME=/u01/app/oracle/middleware/fmw
      - JAVA_HOME=/u01/app/oracle/middleware/jdk17
      - MW_HOME=/u01/app/oracle/middleware
      - DOMAIN_HOME=/u01/app/oracle/middleware/fmw/user_projects/domains/base_domain
      - AUTO_START_SERVICES=${AUTO_START_SERVICES:-true}
      - WLS_USER=${WLS_USER:-weblogic}
      - WLS_PW=${WLS_PW:-Oracle123}
      - DB_HOST=oracle-db
      - DB_PORT=1521
      - DB_SERVICE=${DB_SERVICE:-FREEPDB1}

    user: root
    shm_size: ${SHM_SIZE:-2gb}
    mem_limit: ${MEM_LIMIT:-12g}
    mem_reservation: ${MEM_RESERVATION:-8g}
    cpus: ${CPUS:-4}
    restart: unless-stopped

    depends_on:
      oracle-db:
        condition: service_healthy

    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:7001/console"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 5m

    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

    networks:
      - oracle-forms-network

volumes:
  oracle_db_data:
    driver: local

networks:
  oracle-forms-network:
    name: oracle-forms-network
    driver: bridge
```

Save as `docker-compose.hub.yml` and commit to your repository.

---

## Step 6: Use on Other Machines

On any machine with Docker:

```bash
# Clone your repo or download docker-compose.hub.yml
git clone your-repo-url
cd your-repo

# Create .env file
cat > .env << EOF
DOCKERHUB_USERNAME=your-dockerhub-username
WLS_PW=YourSecurePassword
DB_PASSWORD=YourSecurePassword
VNC_PASSWORD=YourSecurePassword
AUTO_START_SERVICES=true
EOF

# Create required directories
mkdir -p config/forms config/reports config/tnsnames forms_source reports_source reports_temp logs

# Pull and start (no build needed!)
docker-compose -f docker-compose.hub.yml pull
docker-compose -f docker-compose.hub.yml up -d

# Monitor startup
docker logs -f oracle-forms-production
```

**Wait 5-8 minutes** for all services to start, then access:
- WebLogic Console: http://localhost:7001/console
- Forms: http://localhost:9001/forms/frmservlet
- Reports: http://localhost:9002/reports/rwservlet

---

## Docker Hub Repository Setup

### Create Repository

1. Login to https://hub.docker.com
2. Click "Create Repository"
3. Repository Name: `oracle-forms-reports`
4. Description: "Oracle Forms & Reports 14c - Production-ready Docker image"
5. Visibility:
   - **Public**: Free, anyone can pull
   - **Private**: Paid, only authorized users can pull
6. Click "Create"

### Repository Description

Add this to your Docker Hub repository description:

```markdown
# Oracle Forms & Reports 14c

Production-ready Oracle Forms & Reports 14c Docker image with WebLogic Server 14.1.2.

## Quick Start

### With Docker Compose (Recommended)

```bash
# Download docker-compose.hub.yml
wget https://raw.githubusercontent.com/your-repo/oracle-form14/main/docker-compose.hub.yml

# Create .env file
echo "DOCKERHUB_USERNAME=your-username" > .env

# Start services
docker-compose -f docker-compose.hub.yml up -d
```

### Standalone (requires separate database)

```bash
docker run -d \
  --name oracle-forms \
  -p 7001:7001 \
  -p 9001:9001 \
  -p 9002:9012 \
  -e AUTO_START_SERVICES=true \
  your-username/oracle-forms-reports:latest
```

## What's Included

- Oracle Forms 14.1.2.0
- Oracle Reports 14.1.2.0
- WebLogic Server 14.1.2.0
- Java 17 (JDK 17.0.12)
- VNC Server (XFCE4 Desktop)
- Auto-start capability

## Services

- **WebLogic Console**: http://localhost:7001/console
- **Enterprise Manager**: http://localhost:7001/em
- **Forms**: http://localhost:9001/forms/frmservlet
- **Reports**: http://localhost:9002/reports/rwservlet
- **VNC**: vnc://localhost:5901

## Requirements

- Docker 20.10+
- 12GB RAM minimum
- 50GB disk space

## Documentation

Full documentation: https://github.com/your-repo/oracle-form14

## Database

This image requires a separate Oracle Database. We recommend:
```bash
docker run -d --name oracle-db gvenzl/oracle-free:23-slim
```

Or use docker-compose.hub.yml which includes the database.

## License

Oracle software is licensed by Oracle Corporation. This image provides deployment automation only.
```

---

## Best Practices

### Version Tagging

Always tag with multiple versions:

```bash
# Tag with multiple versions for flexibility
docker tag image:latest username/oracle-forms-reports:latest
docker tag image:latest username/oracle-forms-reports:14c
docker tag image:latest username/oracle-forms-reports:14.1.2.0
docker tag image:latest username/oracle-forms-reports:14.1.2.0-20250104  # Date stamp
```

### Security

1. **Change Default Passwords** - Never use Oracle123 in production
2. **Use Private Repository** - For production images
3. **Use Access Tokens** - Instead of Docker Hub password
4. **Don't Include .env** - Never commit passwords to git
5. **Review Security Settings** - In WebLogic Console before pushing

### Testing Before Push

```bash
# Test locally before pushing
docker-compose -f docker-compose.production.yml up -d

# Wait 5-8 minutes
docker logs -f oracle-forms-production

# Verify all services
curl http://localhost:7001/console
curl http://localhost:9001/forms/frmservlet
curl http://localhost:9002/reports/rwservlet

# If everything works, then push
```

### Documentation

Include in your repository:
- `README.md` - Overview and quick start
- `docker-compose.hub.yml` - Ready-to-use compose file
- `.env.example` - Template for environment variables
- `docs/` - Complete documentation

---

## Troubleshooting

### Push Fails - Image Too Large

**Problem**: Docker Hub has size limits for free accounts (10GB for free tier)

**Solutions:**
1. Your image (~10GB) should be within limits
2. Upgrade to Docker Hub Pro for increased limits
3. Use alternative registry (AWS ECR, Azure ACR, Google GCR)
4. Clean up unnecessary layers in Dockerfile

### Slow Upload

**Problem**: Pushing 10GB image takes hours

**Check upload speed:**
```bash
# Test your upload speed
speedtest-cli --simple
```

**Solutions:**
1. Push during off-peak hours
2. Use faster internet connection
3. Consider cloud build service
4. Use registry closer to your location

### Authentication Failed

**Problem**: Cannot push to Docker Hub

```bash
# Logout and login again
docker logout
docker login

# Verify you're logged in
docker info | grep Username

# Make sure image name includes your username
docker images | grep your-username
```

### Cannot Pull on Other Machine

**Problem**: Image not found or authentication required

**Check:**
1. Verify image name: `username/oracle-forms-reports:latest`
2. Check repository visibility (public vs private)
3. Login if private: `docker login`
4. Verify image was pushed: check Docker Hub web interface
5. Check spelling of username and image name

### Image Pull is Slow

**Problem**: Downloading takes hours

**Solutions:**
1. Use faster internet connection
2. Pull during off-peak hours
3. Check Docker Hub status page
4. Consider using a registry mirror

---

## Alternative Registries

If Docker Hub doesn't meet your needs:

### AWS ECR (Elastic Container Registry)

```bash
# Login to AWS ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 123456789012.dkr.ecr.us-east-1.amazonaws.com

# Tag for ECR
docker tag oracle-forms-14c-production:latest 123456789012.dkr.ecr.us-east-1.amazonaws.com/oracle-forms-reports:latest

# Push
docker push 123456789012.dkr.ecr.us-east-1.amazonaws.com/oracle-forms-reports:latest
```

### Azure ACR (Azure Container Registry)

```bash
# Login to Azure ACR
az acr login --name myregistry

# Tag for ACR
docker tag oracle-forms-14c-production:latest myregistry.azurecr.io/oracle-forms-reports:latest

# Push
docker push myregistry.azurecr.io/oracle-forms-reports:latest
```

### Google GCR (Google Container Registry)

```bash
# Login to Google GCR
gcloud auth configure-docker

# Tag for GCR
docker tag oracle-forms-14c-production:latest gcr.io/my-project/oracle-forms-reports:latest

# Push
docker push gcr.io/my-project/oracle-forms-reports:latest
```

---

## Automated Builds (Optional)

Set up GitHub Actions to automatically build and push on commits:

Create `.github/workflows/docker-build.yml`:

```yaml
name: Build and Push Docker Image

on:
  push:
    branches: [ main ]
    tags: [ 'v*' ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2

      - name: Login to Docker Hub
        uses: docker/login-action@v1
        with:
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}

      - name: Build and push
        uses: docker/build-push-action@v2
        with:
          context: .
          file: ./docs/deployment/Dockerfile.production
          push: true
          tags: |
            ${{ secrets.DOCKERHUB_USERNAME }}/oracle-forms-reports:latest
            ${{ secrets.DOCKERHUB_USERNAME }}/oracle-forms-reports:${{ github.ref_name }}
```

---

## Summary

**Recommended Workflow:**

1. ✅ Complete manual installation
2. ✅ Test all services thoroughly
3. ✅ Build production image
4. ✅ Test production image locally
5. ✅ Tag for Docker Hub
6. ✅ Push to Docker Hub
7. ✅ Create docker-compose.hub.yml
8. ✅ Document in README
9. ✅ Share with team

**Your Image:**
- Size: ~10GB (Forms/Reports only)
- Database: Uses public `gvenzl/oracle-free:23-slim`
- Upload time: 30-60 minutes
- Download time: 15-30 minutes
- Production-ready: Yes
- Scalable: Yes

**Your Oracle Forms & Reports 14c Docker image is ready for distribution!** 🚀
