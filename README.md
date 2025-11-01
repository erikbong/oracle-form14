# Oracle Forms & Reports 14c Docker Deployment

A complete Docker-based deployment solution for Oracle Forms & Reports 14c with WebLogic Server 14.1.2, using VNC-based configuration for proper JRF, Enterprise Manager, Forms, and Reports setup.

![Oracle Forms](https://img.shields.io/badge/Oracle%20Forms-14c-red)
![WebLogic](https://img.shields.io/badge/WebLogic-14.1.2.0-blue)
![Docker](https://img.shields.io/badge/Docker-Compose-blue)
![License](https://img.shields.io/badge/License-MIT-green)

## 🚀 Quick Start

### Prerequisites

- Docker Desktop or Docker Engine (with 8GB+ RAM allocated)
- Docker Compose
- VNC Client (TigerVNC, RealVNC, TightVNC, or any VNC viewer)
- Oracle installation files (see [Installation Files](#-installation-files))

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/erikbong/oracle-form14.git
cd oracle-form14

# 2. Place Oracle installation files in install/ directory
# - fmw_14.1.2.0.0_infrastructure.jar (~2.1GB)
# - fmw_14.1.2.0.0_fr_linux64.bin (~1.3GB)
# - jdk-17.0.12_linux-x64_bin.tar.gz (~180MB)

# 3. Build and start containers
docker-compose up -d

# 4. Connect to VNC and create domain (see below)
```

### Domain Creation via VNC

After containers start, create the WebLogic domain using Oracle's Configuration Wizard:

1. **Connect to VNC**
   - Host: `localhost:5901`
   - Password: `Oracle123`

2. **Run Configuration Wizard** (in VNC terminal):
   ```bash
   cd /u01/app/oracle/product/fmw14.1.2.0/oracle_common/common/bin
   ./config.sh
   ```

3. **Configure Domain**:
   - Create new domain at: `/u01/app/oracle/config/domains/forms_domain`
   - Select templates: **Oracle JRF + EM + Forms + Reports**
   - Database: `oracle-db:1521/FREEPDB1`
   - RCU Schema Prefix: `DEV`, Password: `Oracle123`
   - Admin credentials: `weblogic/Oracle123`
   - Domain mode: **Development** (recommended)

4. **Restart Container** (after domain creation completes):
   ```bash
   docker-compose restart oracle-forms
   ```

**Detailed Instructions**: See [docs/DOMAIN_CREATION_GUIDE.md](docs/DOMAIN_CREATION_GUIDE.md)

### Access Services

After startup (wait 3-5 minutes for all servers to start):

| Service | URL | Credentials |
|---------|-----|-------------|
| **WebLogic Console** | http://localhost:7001/console | weblogic/Oracle123 |
| **Forms** | http://localhost:9001/forms/frmservlet | - |
| **Reports** | http://localhost:9002/reports/rwservlet | - |
| **VNC** | localhost:5901 | Oracle123 |

## 📋 Documentation

| Document | Description |
|----------|-------------|
| [DOMAIN_CREATION_GUIDE.md](docs/DOMAIN_CREATION_GUIDE.md) | **Start here** - Complete domain creation walkthrough |
| [INSTALLATION_GUIDE.md](docs/INSTALLATION_GUIDE.md) | Docker build and installation details |
| [FORMS_DEVELOPMENT_GUIDE.md](docs/FORMS_DEVELOPMENT_GUIDE.md) | Oracle Forms development guide |
| [REPORTS_DEVELOPMENT_GUIDE.md](docs/REPORTS_DEVELOPMENT_GUIDE.md) | Oracle Reports development guide |
| [REPORTS_CONFIGURATION_GUIDE.md](docs/REPORTS_CONFIGURATION_GUIDE.md) | Reports server configuration |
| [WEBLOGIC_CONSOLE_GUIDE.md](docs/WEBLOGIC_CONSOLE_GUIDE.md) | WebLogic administration guide |
| [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) | Common issues and solutions |
| [CLAUDE.md](CLAUDE.md) | Technical details for developers |

## 🏗️ Architecture

### Components

- **Oracle Forms & Reports 14c** - Main application container
- **Oracle Database 23c Free** - RCU schema repository
- **WebLogic Server 14.1.2** - Application server infrastructure
- **VNC Server** - GUI access for configuration wizard

### WebLogic Domain

The domain is created via Oracle's Configuration Wizard and includes:

- **AdminServer** (port 7001) - WebLogic admin console
- **WLS_FORMS** (port 9001) - Forms managed server
- **WLS_REPORTS** (port 9002) - Reports managed server
- **Oracle JRF** - Java Required Files (metadata, security, audit)
- **Enterprise Manager** - Application monitoring and management

### Data Persistence

All configuration and data is persisted in Docker volumes:

- `oracle_domain_data` - WebLogic domain configuration
- `oracle_user_projects` - Enterprise Manager and deployed applications
- `oracle_db_data` - RCU schemas (STB, JRF, OPSS, IAU, MDS, WLS)
- `oracle_logs` - Application and server logs
- `oracle_tns_admin` - Database connection configuration
- `oracle_forms_source` - Forms source files (.fmb)
- `oracle_reports_source` - Reports source files (.rdf)
- `oracle_reports_config` - Reports server configuration
- `oracle_applications` - Deployed forms and reports

## 📦 Installation Files

Place these files in the `install/` directory before building:

| File | Description | Download Source |
|------|-------------|-----------------|
| `fmw_14.1.2.0.0_infrastructure.jar` | FMW Infrastructure (~2.1GB) | [Oracle Technology Network](https://www.oracle.com/middleware/technologies/fusionmiddleware-downloads.html) |
| `fmw_14.1.2.0.0_fr_linux64.bin` | Forms & Reports (~1.3GB) | [Oracle Forms Downloads](https://www.oracle.com/middleware/technologies/forms/downloads.html) |
| `jdk-17.0.12_linux-x64_bin.tar.gz` | Oracle JDK 17 (~180MB) | [Oracle JDK Downloads](https://www.oracle.com/java/technologies/downloads/) |

**Note**: Oracle account required. Ensure proper licensing for production use.

## ⚙️ Configuration

### Environment Variables

Key configuration options in `docker-compose.yml`:

```yaml
environment:
  - ORACLE_HOME=/u01/app/oracle/product/fmw14.1.2.0
  - DOMAIN_HOME=/u01/app/oracle/config/domains/forms_domain
  - JAVA_HOME=/u01/app/oracle/product/jdk17
  - ADMIN_USERNAME=weblogic
  - ADMIN_PASSWORD=Oracle123
  - JAVA_OPTIONS=-Xmx2048m -Xms1024m
```

### Custom Configuration

Create `docker-compose.override.yml` to customize:

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

### Basic Deployment

```bash
docker-compose up -d
```

### With Nginx Reverse Proxy

```bash
docker-compose --profile proxy up -d
```

Access via:
- Admin Console: http://localhost/console or http://admin.localhost
- Forms: http://localhost/forms or http://forms.localhost
- Reports: http://localhost/reports or http://reports.localhost

### Production Deployment

For production:
1. Change default passwords in `docker-compose.yml`
2. Configure SSL/TLS for secure connections
3. Adjust resource limits and JVM settings
4. Enable WebLogic production mode during domain creation
5. Implement proper backup strategy
6. Configure monitoring and logging

## 📊 Monitoring & Management

### View Logs

```bash
# Container logs
docker-compose logs -f oracle-forms

# WebLogic AdminServer log
docker exec oracle-forms-14c tail -f /u01/app/oracle/config/domains/forms_domain/AdminServer.log

# Forms server log
docker exec oracle-forms-14c tail -f /u01/app/oracle/config/domains/forms_domain/WLS_FORMS.log

# Reports server log
docker exec oracle-forms-14c tail -f /u01/app/oracle/config/domains/forms_domain/WLS_REPORTS.log
```

### Container Management

```bash
# Check container status
docker-compose ps

# Restart services
docker-compose restart oracle-forms

# Stop all services
docker-compose down

# Stop and remove all data (⚠️ deletes volumes)
docker-compose down -v
```

### Server Management

Access container and manage WebLogic:

```bash
# Enter container
docker exec -it oracle-forms-14c bash

# Check server status
cd /u01/app/oracle/config/domains/forms_domain
./bin/startWebLogic.sh  # Start AdminServer
./bin/stopWebLogic.sh   # Stop AdminServer
```

## 🔧 Troubleshooting

### VNC Connection Issues

```bash
# Check VNC is running
docker logs oracle-forms-14c | grep VNC

# Restart container
docker-compose restart oracle-forms
```

### Domain Creation Fails

If Configuration Wizard fails, clean up and retry:

```bash
# Delete domain directories
docker exec -u root oracle-forms-14c rm -rf /u01/app/oracle/config/domains/forms_domain
docker exec -u root oracle-forms-14c rm -rf /u01/app/oracle/product/fmw14.1.2.0/user_projects/applications/forms_domain

# Reconnect to VNC and run config.sh again
```

### Servers Not Starting

```bash
# Check logs for errors
docker logs oracle-forms-14c --tail 100

# Verify domain exists
docker exec oracle-forms-14c ls -la /u01/app/oracle/config/domains/forms_domain

# Check AdminServer log
docker exec oracle-forms-14c tail -50 /u01/app/oracle/config/domains/forms_domain/AdminServer.log
```

### Database Connection Issues

```bash
# Verify database is running
docker ps | grep oracle-db

# Check database health
docker logs oracle-db

# Test connection from Forms container
docker exec -it oracle-forms-14c sqlplus sys/Oracle123@oracle-db:1521/FREEPDB1 as sysdba
```

**More Solutions**: See [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)

## 💻 Development

### Directory Structure

```
oracle-form14/
├── install/                   # Oracle installation files (user-provided)
│   ├── fmw_14.1.2.0.0_infrastructure.jar
│   ├── fmw_14.1.2.0.0_fr_linux64.bin
│   └── jdk-17.0.12_linux-x64_bin.tar.gz
├── scripts/                   # Container startup and utility scripts
│   └── startAll.sh           # Main startup script (domain detection & server start)
├── response/                  # Silent installation response files
│   ├── infrastructure.rsp
│   └── forms_reports.rsp
├── docs/                      # Documentation
│   ├── DOMAIN_CREATION_GUIDE.md
│   ├── INSTALLATION_GUIDE.md
│   └── ...
├── docker-compose.yml         # Main deployment configuration
├── Dockerfile                 # Container build definition
├── nginx.conf                 # Reverse proxy configuration
├── .env.example              # Environment template
├── .gitignore
├── CLAUDE.md                  # Developer technical reference
├── LICENSE
└── README.md                  # This file
```

### Building Custom Images

```bash
# Build with custom tag
docker build -t my-oracle-forms:14c .

# Build without cache
docker-compose build --no-cache

# Build and start
docker-compose up -d --build
```

## 🔒 Security Considerations

### Production Checklist

- [ ] Change default WebLogic admin password
- [ ] Change default VNC password (rebuild image)
- [ ] Use WebLogic Production mode
- [ ] Configure SSL/TLS certificates
- [ ] Restrict network access (firewall rules)
- [ ] Enable WebLogic security features
- [ ] Regular security patches and updates
- [ ] Implement backup and disaster recovery
- [ ] Enable audit logging
- [ ] Use secrets management (Docker secrets, vault, etc.)

### Network Security

```yaml
# Restrict external access
services:
  oracle-forms:
    ports:
      - "127.0.0.1:7001:7001"  # Localhost only
      - "127.0.0.1:9001:9001"
      - "127.0.0.1:9002:9002"
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/improvement`)
3. Make your changes and test thoroughly
4. Commit changes (`git commit -am 'Add new feature'`)
5. Push to branch (`git push origin feature/improvement`)
6. Create a Pull Request

## 📝 License

This project is licensed under the MIT License - see [LICENSE](LICENSE) for details.

**Important**: Oracle products require separate licensing. Ensure compliance with Oracle licensing terms for production deployments.

## 🆘 Support

- **Issues**: https://github.com/erikbong/oracle-form14/issues
- **Discussions**: https://github.com/erikbong/oracle-form14/discussions
- **Documentation**: See [docs/](docs/) folder

## 🏷️ Version Information

- **Project Version**: 2.0.0
- **Oracle Forms**: 14c (14.1.2.0.0)
- **Oracle Reports**: 14c (14.1.2.0.0)
- **WebLogic Server**: 14.1.2.0.0
- **Oracle Database**: 23c Free (for RCU schemas)
- **Base Image**: Oracle Linux 8 Slim
- **Java**: Oracle JDK 17.0.12
- **Docker Compose**: 3.8
- **Last Updated**: October 2025

## ✨ What's New in v2.0

- **VNC-based Domain Creation**: Use Oracle's official Configuration Wizard for proper setup
- **Oracle Database 23c Free**: Integrated database for RCU schemas
- **Full JRF Support**: Proper Java Required Files configuration
- **Enterprise Manager**: Complete EM deployment and integration
- **Persistent Volumes**: All data preserved across container restarts
- **Automated Server Startup**: Domain detection and automatic server initialization
- **Improved Documentation**: Step-by-step guides for all processes

---

**Built with ❤️ using Docker and Oracle technologies**

For technical details and architecture, see [CLAUDE.md](CLAUDE.md).
