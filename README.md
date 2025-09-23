# Oracle Forms & Reports 14c Docker Deployment

A complete Docker-based deployment solution for Oracle Forms & Reports 14c using Oracle Linux 8, WebLogic Server, and containerized architecture.

![Oracle Forms](https://img.shields.io/badge/Oracle%20Forms-14c-red)
![WebLogic](https://img.shields.io/badge/WebLogic-14.1.2.0-blue)
![Docker](https://img.shields.io/badge/Docker-Compose-blue)
![License](https://img.shields.io/badge/License-MIT-green)

## 🚀 Quick Start

### Prerequisites

- Docker Desktop or Docker Engine
- Docker Compose
- 8GB+ RAM available for containers
- Oracle installation files (see [Installation Files](#installation-files))

### Deploy with Docker Compose

```bash
# Clone the repository
git clone https://github.com/erikbong/oracle-form14.git
cd oracle-form14

# Place Oracle installation files in install/ directory
# (see Installation Files section below)

# STEP 1: Initialize host directories (REQUIRED for fresh installations)
docker-compose --profile init up oracle-forms-init

# STEP 2: Build and start the main services
docker-compose up -d

# With nginx reverse proxy (optional)
docker-compose --profile proxy up -d
```

### Access the Services

- **WebLogic Console**: http://localhost:7001/console *(Welcome page - see [Console Guide](WEBLOGIC_CONSOLE_GUIDE.md))*
- **Forms Service**: http://localhost:9001
- **Reports Service**: http://localhost:9002

**Default Credentials**: `weblogic` / `Oracle123`

> **📋 Console Access**: WebLogic 14.1.2 uses the WebLogic Remote Console (desktop app). See [WEBLOGIC_CONSOLE_GUIDE.md](WEBLOGIC_CONSOLE_GUIDE.md) for complete setup instructions.

## 📋 Table of Contents

- [Architecture Overview](#architecture-overview)
- [Installation Files](#installation-files)
- [Configuration](#configuration)
- [Deployment Options](#deployment-options)
- [Service Access](#service-access)
- [Monitoring & Logs](#monitoring--logs)
- [Troubleshooting](#troubleshooting)
- [Development](#development)
- [Contributing](#contributing)

## 📚 Additional Documentation

- **[INSTALLATION_GUIDE.md](INSTALLATION_GUIDE.md)** - Detailed step-by-step installation instructions
- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** - Comprehensive troubleshooting guide with solutions
- **[CLAUDE.md](CLAUDE.md)** - Technical documentation for developers and Claude Code

## 🏗️ Architecture Overview

### Components

| Component | Description | Port | Technology |
|-----------|-------------|------|------------|
| **Oracle Forms** | Main Forms & Reports container | 7001, 9001, 9002 | Oracle Linux 8, WebLogic 14.1.2.0 |
| **Nginx Proxy** | Reverse proxy (optional) | 80, 443 | Nginx Alpine |
| **Volumes** | Persistent data storage | - | Docker Volumes |

### Container Architecture

```
┌─────────────────┐    ┌─────────────────┐
│   Nginx Proxy   │    │  Oracle Forms   │
│   (Optional)    │───▶│     14c         │
│   Port 80/443   │    │  WebLogic 14.1  │
└─────────────────┘    │  Ports 7001-9002│
                       └─────────────────┘
                                │
                       ┌─────────────────┐
                       │ Persistent Data │
                       │   - Domain      │
                       │   - Logs        │
                       └─────────────────┘
```

### WebLogic Domain Structure

- **AdminServer** (7001): WebLogic administration console
- **forms_server1** (9001): Oracle Forms managed server
- **reports_server1** (9002): Oracle Reports managed server
- **NodeManager**: Service coordination and management

## 📦 Installation Files

Place the following Oracle installation files in the `install/` directory before building:

| File | Description | Size |
|------|-------------|------|
| `fmw_14.1.2.0.0_infrastructure.jar` | WebLogic + JRF Infrastructure | ~2.1GB |
| `fmw_14.1.2.0.0_fr_linux64.bin` | Forms & Reports Binaries | ~1.3GB |
| `jdk-17.0.12_linux-x64_bin.tar.gz` | Oracle JDK 17 | ~180MB |

### Download Sources

- **Oracle Technology Network**: https://www.oracle.com/middleware/technologies/forms/downloads.html
- **Oracle JDK**: https://www.oracle.com/java/technologies/downloads/

**Note**: Oracle account required for downloads. Ensure you have proper licensing for production use.

## ⚙️ Configuration

### Environment Variables

Create a `.env` file from the provided template:

```bash
cp .env.example .env
```

Key configuration options:

```bash
# WebLogic Admin Credentials
ADMIN_USERNAME=weblogic
ADMIN_PASSWORD=Oracle123

# Port Configuration
ADMIN_PORT=7001
FORMS_PORT=9001
REPORTS_PORT=9002

# JVM Settings
JAVA_OPTIONS=-Xmx2048m -Xms1024m

# Resource Limits
MEMORY_LIMIT=4G
CPU_LIMIT=2.0
```

### Custom Configuration

Override default settings with `docker-compose.override.yml`:

```yaml
version: '3.8'
services:
  oracle-forms:
    environment:
      - ADMIN_PASSWORD=YourSecurePassword
      - JAVA_OPTIONS=-Xmx4096m -Xms2048m
    ports:
      - "8001:7001"  # Custom external port
```

## 🚀 Deployment Options

### 1. Basic Deployment

```bash
# Build and start Oracle Forms only
docker-compose up -d oracle-forms
```

### 2. Full Stack with Proxy

```bash
# Include nginx reverse proxy
docker-compose --profile proxy up -d
```

### 3. Development Mode

```bash
# Build without cache for development
docker-compose build --no-cache
docker-compose up -d
```

### 4. Production Deployment

```bash
# Use specific resource limits
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

## 🌐 Service Access

### Direct Access

| Service | URL | Description |
|---------|-----|-------------|
| WebLogic Console | http://localhost:7001/console | Admin interface |
| Forms Service | http://localhost:9001 | Forms runtime |
| Reports Service | http://localhost:9002 | Reports engine |

### Nginx Proxy Access (with `--profile proxy`)

| Service | URL | Alternative |
|---------|-----|-------------|
| Admin Console | http://localhost/console | http://admin.localhost |
| Forms | http://localhost/forms | http://forms.localhost |
| Reports | http://localhost/reports | http://reports.localhost |

### Health Check

```bash
# Check container health
docker-compose ps

# Check WebLogic console availability
curl -f http://localhost:7001/console
```

## 📊 Monitoring & Logs

### Container Logs

```bash
# View all logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f oracle-forms

# View build logs
docker-compose logs --tail=100 oracle-forms
```

### WebLogic Logs

```bash
# Access container
docker-compose exec oracle-forms bash

# View domain logs
tail -f /u01/app/oracle/config/domains/forms_domain/servers/AdminServer/logs/AdminServer.log
```

### Persistent Data

Data is stored in Docker volumes:

- `oracle_domain_data`: WebLogic domain configuration
- `oracle_logs`: Application and server logs

```bash
# List volumes
docker volume ls | grep oracle

# Inspect volume
docker volume inspect oracle_domain_data
```

## 🔧 Troubleshooting

### Common Issues

#### 1. Build Failures

**Issue**: Docker build fails with package installation errors
```bash
Error: Failed to download packages
```

**Solution**:
- Check internet connectivity
- Ensure Docker has sufficient resources (8GB+ RAM)
- Retry build: `docker-compose build --no-cache`

#### 2. Container Startup Issues

**Issue**: Container exits immediately
```bash
docker-compose ps
# shows container as "Exited"
```

**Solution**:
- Check logs: `docker-compose logs oracle-forms`
- Verify installation files are present in `install/`
- Ensure ports 7001-9002 are not in use

#### 3. WebLogic Console Access

**Issue**: Cannot access http://localhost:7001/console
```bash
curl: (7) Failed to connect to localhost port 7001
```

**Solution**:
- Wait 2-3 minutes for full startup
- Check container health: `docker-compose ps`
- Verify port mapping: `docker port $(docker-compose ps -q oracle-forms)`

#### 4. Memory Issues

**Issue**: Container killed due to OOM
```bash
docker-compose logs oracle-forms
# shows "Killed" or memory-related errors
```

**Solution**:
- Increase Docker memory allocation to 8GB+
- Reduce JVM heap size in environment variables
- Add swap space to host system

### Advanced Troubleshooting

```bash
# Access container shell
docker-compose exec oracle-forms bash

# Check WebLogic processes
ps aux | grep java

# Check domain status
cd /u01/app/oracle/config/domains/forms_domain
./bin/stopWebLogic.sh
./bin/startWebLogic.sh

# Check network connectivity
netstat -tlnp | grep 7001
```

### Debug Mode

Enable debug logging:

```yaml
# docker-compose.override.yml
services:
  oracle-forms:
    environment:
      - JAVA_OPTIONS=-Xmx2048m -Xms1024m -Dweblogic.debug.DebugAll=true
```

## 💻 Development

### Local Development Setup

1. **Clone and Setup**
   ```bash
   git clone https://github.com/erikbong/oracle-form14.git
   cd oracle-form14
   cp .env.example .env
   ```

2. **Modify Configuration**
   - Edit `.env` for development settings
   - Customize `docker-compose.override.yml` if needed

3. **Development Build**
   ```bash
   docker-compose build --no-cache
   docker-compose up -d
   ```

### File Structure

```
oracle-form14/
├── install/                 # Oracle installation files (user-provided)
├── scripts/                 # WebLogic domain creation scripts
├── response/                # Silent installation response files
├── docker-compose.yml       # Main deployment configuration
├── Dockerfile              # Oracle Forms container build
├── nginx.conf              # Nginx proxy configuration
├── .env.example            # Environment template
├── CLAUDE.md               # Developer documentation
└── README.md               # This file
```

### Building Custom Images

```bash
# Build with custom tag
docker build -t my-oracle-forms:latest .

# Build with build arguments
docker build --build-arg ORACLE_VERSION=14.1.2.0 .
```

### Testing

```bash
# Test container health
docker-compose exec oracle-forms curl -f http://localhost:7001/console

# Test all services
./test-services.sh  # (create this script for automated testing)
```

## 📈 Performance Tuning

### Resource Optimization

```yaml
# docker-compose.override.yml
services:
  oracle-forms:
    deploy:
      resources:
        limits:
          memory: 6G
          cpus: '3.0'
        reservations:
          memory: 4G
          cpus: '2.0'
    environment:
      - JAVA_OPTIONS=-Xmx4096m -Xms2048m -XX:+UseG1GC
```

### Storage Performance

```yaml
# Use local bind mounts for better performance
volumes:
  - ./data/domains:/u01/app/oracle/config/domains
  - ./data/logs:/u01/app/oracle/product/fmw14.1.2.0/logs
```

## 🔒 Security Considerations

### Production Deployment

1. **Change Default Credentials**
   ```bash
   # Update .env file
   ADMIN_PASSWORD=YourSecurePassword123!
   ```

2. **Network Security**
   ```yaml
   # Restrict external access
   services:
     oracle-forms:
       ports:
         - "127.0.0.1:7001:7001"  # Localhost only
   ```

3. **SSL/TLS Configuration**
   - Configure SSL certificates in nginx
   - Enable WebLogic SSL
   - Use secure communication between services

### Access Control

- Implement WebLogic security realms
- Configure role-based access control
- Enable audit logging
- Regular security updates

## 🤝 Contributing

1. **Fork the Repository**
2. **Create Feature Branch**
   ```bash
   git checkout -b feature/new-functionality
   ```
3. **Make Changes and Test**
4. **Submit Pull Request**

### Development Guidelines

- Follow Oracle best practices
- Test all changes thoroughly
- Update documentation
- Include proper commit messages

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

**Note**: Oracle products require separate licensing. Ensure compliance with Oracle licensing terms for production use.

## 📖 Quick Reference

| Task | Command | Documentation |
|------|---------|---------------|
| **First-time setup** | See installation guide | [INSTALLATION_GUIDE.md](INSTALLATION_GUIDE.md) |
| **Quick start** | `docker-compose up -d` | [README.md](#quick-start) |
| **Troubleshooting** | Check logs and solutions | [TROUBLESHOOTING.md](TROUBLESHOOTING.md) |
| **Development** | Technical details | [CLAUDE.md](CLAUDE.md) |

## 🆘 Support

- **Issues**: https://github.com/erikbong/oracle-form14/issues
- **Discussions**: https://github.com/erikbong/oracle-form14/discussions
- **Documentation**: See [CLAUDE.md](CLAUDE.md) for detailed technical information

## 🏷️ Version Information

- **Project Version**: 1.0.0
- **Oracle Forms**: 14c (14.1.2.0.0)
- **WebLogic Server**: 14.1.2.0.0
- **Base Image**: Oracle Linux 8 Slim
- **Docker Compose**: 3.8
- **Last Updated**: September 2025

---

**Built with ❤️ using Docker and Oracle technologies**

For detailed technical documentation and development guidance, see [CLAUDE.md](CLAUDE.md).