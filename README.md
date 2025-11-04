# Oracle Forms & Reports 14c Docker Deployment

A complete Docker-based deployment solution for Oracle Forms & Reports 14c with WebLogic Server 14.1.2, featuring manual installation via VNC and production-ready containerization.

![Oracle Forms](https://img.shields.io/badge/Oracle%20Forms-14c-red)
![WebLogic](https://img.shields.io/badge/WebLogic-14.1.2.0-blue)
![Docker](https://img.shields.io/badge/Docker-Compose-blue)
![Docker Hub](https://img.shields.io/badge/Docker%20Hub-Ready-blue)
![License](https://img.shields.io/badge/License-MIT-green)

---

## 📦 Docker Hub

Pre-built production-ready images available:
- **Forms & Reports**: `bbquerre/oracle-forms-14c:latest` (5GB) - Requires Oracle folder mounted
- **Database with RCU**: `bbquerre/oracle-db-with-rcu:latest` (1.5GB compressed, 7.6GB extracted)

**Quick Start:**
```bash
# Pull images
docker pull bbquerre/oracle-forms-14c:latest
docker pull bbquerre/oracle-db-with-rcu:latest

# Update docker-compose.yml to use Docker Hub images (uncomment the Docker Hub image lines)
# Start services
docker-compose up -d
```

**Note**: The Forms image requires the `./Oracle/` directory to be mounted. See deployment section for details.

---

## 🚀 Quick Start

### Prerequisites

1. **Install Docker & Docker Compose**
2. **Prepare Oracle Installation** (one of the following):
   - **Option A**: Complete the manual installation to create `./Oracle/` directory
   - **Option B**: Obtain `./Oracle/` directory from an existing installation

### Standard Deployment (Recommended)

```bash
# Clone repository
git clone https://github.com/erikbong/oracle-form14.git
cd oracle-form14

# Ensure ./Oracle/ directory exists with Oracle installation
# If not, you need to perform manual installation first

# Copy and configure environment
cp .env.example .env
# Edit .env and change passwords for production!

# Start all services
docker-compose up -d

# Monitor startup (services take 5-8 minutes to start)
docker logs -f oracle-forms-14c
```

**Service Access** (after 5-8 minutes):
- **VNC**: vnc://localhost:5901 (password: Oracle123)
- **WebLogic Console**: http://localhost:7001/console
- **Forms**: http://localhost:9001/forms/frmservlet
- **Reports**: http://localhost:9002/reports/rwservlet
- **Database**: localhost:1521/FREEPDB1

---

### Using Docker Hub Images

To use pre-built images from Docker Hub instead of local images:

```bash
# Edit docker-compose.yml and change:
# FROM: image: oracle-forms-14c:latest
# TO:   image: bbquerre/oracle-forms-14c:latest

# Then start services
docker-compose up -d
```

**Note**: Even with Docker Hub images, you still need the `./Oracle/` directory mounted, as it's not baked into the image due to Docker build limitations with symlinks.

---

## 📊 Current Deployment Architecture

| Component | Details |
|-----------|---------|
| **Forms & Reports Image** | `oracle-forms-14c:latest` or `bbquerre/oracle-forms-14c:latest` (5GB) |
| **Database Image** | `bbquerre/oracle-db-with-rcu:latest` (1.5GB compressed, 7.6GB extracted) |
| **Oracle Installation** | Mounted from host `./Oracle/` directory |
| **WebLogic Domain** | `base_domain` with AdminServer, WLS_FORMS, WLS_REPORTS |
| **Setup Time** | ~5-8 minutes (services startup) |
| **Auto-Start** | ✅ Yes (via entrypoint.sh) |
| **Database RCU** | ✅ Baked into database image |
| **Configuration** | External mount from `./config/` |

**Key Feature**: The database image includes RCU schemas (STB, OPSS, IAU, IAU_VIEWER, IAU_APPEND, MDS) baked in, so no RCU installation is needed.

---

## 🌐 Service Access

After startup (wait 5-8 minutes for all services):

| Service | URL | Credentials |
|---------|-----|-------------|
| **VNC Desktop** | vnc://localhost:5901 | Oracle123 |
| **WebLogic Console** | http://localhost:7001/console | weblogic/Oracle123 |
| **Enterprise Manager** | http://localhost:7001/em | weblogic/Oracle123 |
| **Forms** | http://localhost:9001/forms/frmservlet | - |
| **Reports** | http://localhost:9002/reports/rwservlet | - |
| **Oracle Database** | localhost:1521/FREEPDB1 | rcu_user/Oracle123 |

**⚠️ Change default passwords in production!**

---

## 📋 Documentation

### 📖 Getting Started
| Document | Description |
|----------|-------------|
| **[COMPLETE_INSTALLATION_GUIDE.md](docs/COMPLETE_INSTALLATION_GUIDE.md)** | **📘 Complete step-by-step installation guide** |
| [deployment/DEPLOYMENT_COMPARISON.md](docs/deployment/DEPLOYMENT_COMPARISON.md) | Compare deployment options |
| [deployment/PRODUCTION_CHECKLIST.md](docs/deployment/PRODUCTION_CHECKLIST.md) | Production deployment checklist |

### 🚀 Deployment Guides
| Document | Description |
|----------|-------------|
| [deployment/PRODUCTION_GUIDE.md](docs/deployment/PRODUCTION_GUIDE.md) | Production deployment guide |
| [deployment/DOCKERHUB_GUIDE.md](docs/deployment/DOCKERHUB_GUIDE.md) | Push/pull from Docker Hub |
| [deployment/AUTO_START_GUIDE.md](docs/deployment/AUTO_START_GUIDE.md) | Auto-start configuration |
| [deployment/BACKUP_GUIDE.md](docs/deployment/BACKUP_GUIDE.md) | Backup and restore procedures |
| [deployment/INSTALLATION_GUIDE.md](docs/deployment/INSTALLATION_GUIDE.md) | Docker build details |
| [deployment/WHATS_NEW.md](docs/deployment/WHATS_NEW.md) | What's new in this release |

### ⚙️ Configuration Guides
| Document | Description |
|----------|-------------|
| [configuration/DOMAIN_CREATION_GUIDE.md](docs/configuration/DOMAIN_CREATION_GUIDE.md) | WebLogic domain creation |
| [configuration/WEBLOGIC_CONSOLE_GUIDE.md](docs/configuration/WEBLOGIC_CONSOLE_GUIDE.md) | WebLogic administration |
| [configuration/REPORTS_CONFIGURATION_GUIDE.md](docs/configuration/REPORTS_CONFIGURATION_GUIDE.md) | Reports server configuration |
| [configuration/REPORTS_SERVER_CONFIGURATION.md](docs/configuration/REPORTS_SERVER_CONFIGURATION.md) | Advanced Reports config |

### 💻 Development Guides
| Document | Description |
|----------|-------------|
| [development/FORMS_DEVELOPMENT_GUIDE.md](docs/development/FORMS_DEVELOPMENT_GUIDE.md) | Oracle Forms development |
| [development/REPORTS_DEVELOPMENT_GUIDE.md](docs/development/REPORTS_DEVELOPMENT_GUIDE.md) | Oracle Reports development |

### 🔧 Troubleshooting & Reference
| Document | Description |
|----------|-------------|
| [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) | Common issues and solutions |
| [CLAUDE.md](CLAUDE.md) | Technical details for developers |

---

## 🏗️ Architecture

### Components

- **Oracle Forms & Reports 14.1.2.0** - Main application container
- **WebLogic Server 14.1.2.0** - Application server infrastructure
- **Oracle JDK 17** - Java runtime
- **Oracle Database 23c Free** - RCU schema repository (separate container)
- **VNC Server** - Remote desktop access (XFCE4)
- **Node Manager** - WebLogic server management

### Directory Structure

```
oracle_form_14c/
├── README.md                          # This file
├── CLAUDE.md                          # Technical reference for developers
│
├── docker-compose.yml                 # Main deployment configuration
├── Dockerfile                         # Forms & Reports image (if building)
├── Dockerfile.db-rcu                  # Database image with RCU
├── entrypoint.sh                      # Auto-start script
│
├── .env                               # Environment configuration (active)
├── .env.example                       # Environment template
│
├── Oracle/                            # Oracle installation (mounted into container)
│   ├── jdk17/                        # Oracle JDK 17
│   ├── fmw/                          # Oracle Fusion Middleware Home
│   │   └── user_projects/domains/base_domain/  # WebLogic domain
│   ├── startAllServices.sh           # Start all services
│   └── stopAllServices.sh            # Stop all services
│
├── db_data/                           # Database export data
│   └── rcu_data.tar.gz               # RCU database export (for building DB image)
│
├── config/                            # External configuration (mounted)
│   ├── forms/                        # Forms configuration
│   ├── reports/                      # Reports configuration
│   └── tnsnames/                     # Database connections
│
├── forms_source/                      # Your Forms (.fmb) files
├── reports_source/                    # Your Reports (.rdf) files
├── reports_temp/                      # Reports temporary files
├── logs/                             # Service logs
│
└── docs/                             # Complete documentation
    ├── COMPLETE_INSTALLATION_GUIDE.md
    ├── TROUBLESHOOTING.md
    ├── MERGED_SETUP.md               # Merged setup documentation
    │
    ├── deployment/                   # Deployment guides
    │   ├── entrypoint.sh             # Original auto-start script
    │   └── [various guides...]
    │
    ├── configuration/                # Configuration guides
    │   └── [various guides...]
    │
    └── development/                  # Development guides
        └── [various guides...]
```

---

## 💡 Features

- ✅ **VNC Desktop** - Full XFCE4 desktop environment for GUI access
- ✅ **Auto-Start** - All services (NodeManager, AdminServer, Forms, Reports) start automatically
- ✅ **Database with RCU** - Pre-configured Oracle 23c Free with RCU schemas baked in
- ✅ **WebLogic Domain** - Pre-configured `base_domain` with all managed servers
- ✅ **Config Mounting** - External configuration files for easy customization
- ✅ **Health Checks** - Automatic service monitoring for both Forms and Database
- ✅ **Resource Limits** - Configurable memory and CPU controls
- ✅ **Docker Hub Ready** - Pre-built images available for quick deployment
- ✅ **Persistent Storage** - Oracle installation in `./Oracle/` on host
- ✅ **Production Ready** - Complete stack with monitoring and auto-restart

---

## 📚 Prerequisites

### System Requirements
- **CPU**: 4+ cores recommended
- **RAM**: 16GB minimum, 24GB recommended
- **Disk**: 60GB free space minimum
- **OS**: Windows, macOS, or Linux with Docker support

### Software
- Docker Desktop or Docker Engine (20.10+)
- Docker Compose (v2.0+)
- VNC Client (TigerVNC, RealVNC, TightVNC, or built-in)
- Git (optional)

### Oracle Installation Files
Download from [Oracle Technology Network](https://www.oracle.com/middleware/technologies/fusionmiddleware-downloads.html):
1. JDK 17 (`jdk-17.0.12_linux-x64_bin.tar.gz` ~180MB)
2. FMW Infrastructure (`fmw_14.1.2.0.0_infrastructure.jar` ~2.1GB)
3. Forms & Reports (`fmw_14.1.2.0.0_fr_linux64.bin` ~1.3GB)

---

## 🔄 Typical Workflow

```
1. Initial Setup
   └─> Manual installation to create ./Oracle/ directory
       └─> Configure WebLogic domain (base_domain)
           └─> Test all services work correctly

2. Development
   └─> Develop Forms (.fmb) and Reports (.rdf) files
       └─> Test via http://localhost:9001/forms and :9002/reports
           └─> Use VNC for GUI access when needed

3. Production Deployment
   └─> Update .env with production passwords
       └─> docker-compose up -d
           └─> Monitor logs: docker logs -f oracle-forms-14c

4. Distribution (Optional)
   └─> Push images to Docker Hub
       └─> Share with team or deploy to cloud
```

---

## 🎯 Use Cases

- 🚀 **Production Deployment** - Complete Forms & Reports environment ready to deploy
- 👥 **Team Development** - Share pre-configured environment via Docker Hub
- ☁️ **Cloud Deployment** - Deploy to AWS, Azure, GCP with Docker Compose
- 🎭 **Multiple Environments** - Easily spin up dev, staging, and production instances
- 📚 **Learning & Training** - Quick setup for Oracle Forms & Reports training
- 🔧 **Development & Testing** - Isolated environment for development work

---

## 🔐 Security Notes

**Default Passwords (Change in Production!):**
- WebLogic: `weblogic` / `Oracle123`
- Database SYS: `Oracle123`
- Database APP: `rcu_user` / `Oracle123`
- VNC: `Oracle123`

**Before Production:**
1. ✅ Change all passwords in `.env` file
2. ✅ Enable SSL/TLS for WebLogic
3. ✅ Configure firewall rules
4. ✅ Use private Docker Hub repository
5. ✅ Enable WebLogic production mode
6. ✅ Review security settings in WebLogic Console

---

## 🤝 Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Test your changes thoroughly
4. Submit a pull request with clear description

---

## 📝 License

This project is licensed under the MIT License. See LICENSE file for details.

**Note:** Oracle Forms, Reports, WebLogic Server, and Oracle Database are licensed by Oracle Corporation. This project provides deployment automation only.

---

## 🆘 Support

### Having Issues?

1. **Check Logs:**
   ```bash
   docker logs -f oracle-forms-14c
   docker logs -f oracle-db
   ```

2. **Review Documentation:**
   - [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) - Common issues and solutions
   - [CLAUDE.md](CLAUDE.md) - Technical reference for developers

3. **Verify Resources:**
   ```bash
   docker stats
   ```
   Ensure sufficient RAM (12GB+ for Forms, 1GB+ for DB) and CPU (4+ cores)

4. **Check Services:**
   ```bash
   # Check if services are running inside container
   docker exec oracle-forms-14c ps aux | grep java

   # Test service endpoints
   curl http://localhost:7001/console
   curl http://localhost:9001/forms/frmservlet
   curl http://localhost:9002/reports/rwservlet
   ```

5. **Community:**
   - Open an issue on GitHub
   - Check existing issues for solutions
   - Review closed issues for similar problems

---

## 📞 Links

- **Repository**: https://github.com/erikbong/oracle-form14
- **Docker Hub Images**:
  - Forms & Reports: https://hub.docker.com/r/bbquerre/oracle-forms-14c
  - Database with RCU: https://hub.docker.com/r/bbquerre/oracle-db-with-rcu
- **Oracle Downloads**: https://www.oracle.com/middleware/technologies/fusionmiddleware-downloads.html
- **Documentation**: See `docs/` directory

---

## ✨ Quick Commands

```bash
# Start Services
docker-compose up -d

# Stop Services
docker-compose down

# View Logs (Real-time)
docker logs -f oracle-forms-14c
docker logs -f oracle-db

# Check Container Status
docker ps

# Check Service Status Inside Container
docker exec oracle-forms-14c ps aux | grep java

# Access Container Shell
docker exec -it oracle-forms-14c bash

# Restart Services
docker-compose restart

# Rebuild and Restart (after changes)
docker-compose down
docker-compose up -d

# View Resource Usage
docker stats
```

---

**Ready to deploy Oracle Forms & Reports 14c in Docker!** 🚀

---

## 🔑 Key Information

**WebLogic Domain**: `base_domain` (located at `/u01/app/oracle/middleware/fmw/user_projects/domains/base_domain`)

**Managed Servers**:
- AdminServer - Port 7001 (WebLogic console)
- WLS_FORMS - Port 9001 (Forms server)
- WLS_REPORTS - Port 9012 (Reports server, mapped to 9002 on host)

**Database**: Oracle 23c Free with RCU schemas (STB, OPSS, IAU, IAU_VIEWER, IAU_APPEND, MDS) pre-installed

**Important Notes**:
- First startup takes 5-8 minutes for all services to initialize
- Services start automatically via `entrypoint.sh`
- The `./Oracle/` directory must exist and contain the complete Oracle installation
- Change all default passwords before production use!
