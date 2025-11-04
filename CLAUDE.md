# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

**For general users and deployment information, see [README.md](README.md)**

## Overview

This is a Docker-based Oracle Forms & Reports 14c deployment project with Oracle Database 23c Free. The repository contains everything needed to run Oracle Forms and Reports 14c in a containerized environment using Docker Hub images.

**Repository**: https://github.com/erikbong/oracle-form14.git
**Docker Hub**:
- Forms & Reports: https://hub.docker.com/r/bbquerre/oracle-forms-14c
- Database with RCU: https://hub.docker.com/r/bbquerre/oracle-db-with-rcu

## Documentation Structure

**IMPORTANT: All documentation files (*.md) MUST be created in the `/docs/` folder, with the following exceptions:**
- **README.md** - Main project documentation (root level only)
- **CLAUDE.md** - This file - Technical guidance for Claude Code (root level only)

### Root Level Files
- **[README.md](README.md)**: Complete user guide with quick start, deployment options, troubleshooting
- **[CLAUDE.md](CLAUDE.md)**: This file - Technical guidance for Claude Code development
- **[.env](.env)**: Active environment configuration
- **[.env.example](.env.example)**: Environment configuration template
- **[docker-compose.yml](docker-compose.yml)**: Main deployment configuration (merged setup)
- **[entrypoint.sh](entrypoint.sh)**: Auto-start script for containers

### Documentation Folder Structure
All other documentation must be organized in `/docs/`:
- **docs/deployment/** - Deployment guides, production setup, Docker Hub instructions
- **docs/configuration/** - WebLogic, Forms, Reports configuration guides
- **docs/development/** - Development guides, Forms/Reports development documentation
- **docs/COMPLETE_INSTALLATION_GUIDE.md** - Comprehensive installation guide
- **docs/MERGED_SETUP.md** - Setup summary and merge documentation
- **docs/TROUBLESHOOTING.md** - Troubleshooting guide

## Current Architecture

### Base Setup
- **Forms Image**: Oracle Linux 8 Slim + XFCE Desktop + VNC + WebLogic environment
- **Database Image**: Oracle 23c Free + RCU schemas pre-installed
- **Oracle FMW Version**: 14.1.2.0 (Forms & Reports)
- **Java Version**: Oracle JDK 17
- **WebLogic Domain**: `base_domain` with AdminServer and managed servers

### Key Components

1. **Oracle Forms & Reports Container** (`oracle-forms-14c`)
   - VNC Server on port 5901 (XFCE desktop)
   - AdminServer (WebLogic) on port 7001
   - WLS_FORMS managed server on port 9001
   - WLS_REPORTS managed server on port 9012 (mapped to 9002 on host)
   - NodeManager for server management
   - Auto-start capability via entrypoint.sh

2. **Oracle Database Container** (`oracle-db`)
   - Oracle 23c Free Database on port 1521
   - RCU Schemas pre-installed: STB, OPSS, IAU, IAU_VIEWER, IAU_APPEND, MDS
   - App User: rcu_user / Oracle123
   - Database data baked into image (no volume needed)

### Directory Structure

```
oracle_form_14c/
├── .env                      # Active environment config
├── .env.example              # Template
├── docker-compose.yml        # Main compose (merged & active)
├── Dockerfile               # Forms Dockerfile (for future with Oracle baked in)
├── Dockerfile.db-rcu        # Database Dockerfile (includes RCU data)
├── entrypoint.sh            # Auto-start script
├── Oracle/                  # (gitignored) Oracle Forms & Reports installation
│   ├── jdk17/              # Oracle JDK 17
│   └── fmw/                # Forms & Reports installation
├── db_data/                 # (gitignored) RCU export for building DB image
├── install/                 # Oracle installer files
├── forms_source/            # Your .fmb files
├── reports_source/          # Your .rdf files
├── scripts/                 # Utility scripts
├── docs/                    # All documentation
└── README.md               # Main user documentation
```

## Deployment Methods

### Method 1: Local Images with Oracle Mounted (Current Active)

**Use case**: Development, testing, when you have Oracle installation locally

```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# View logs
docker logs -f oracle-forms-14c
```

**Requirements**:
- `./Oracle/` folder with complete Oracle Forms & Reports installation
- `entrypoint.sh` in project root
- Local image: `oracle-forms-14c:latest`

**How it works**:
- Oracle folder is mounted from host: `./Oracle:/u01/app/oracle/middleware:rw`
- Database uses Docker Hub image with RCU pre-installed
- Services auto-start via entrypoint.sh

### Method 2: Docker Hub Images (For Others)

**Use case**: Production, sharing with team, clean deployment

```bash
# Pull images from Docker Hub
docker pull bbquerre/oracle-forms-14c:latest
docker pull bbquerre/oracle-db-with-rcu:latest

# Update docker-compose.yml to use Docker Hub images
# Change line 12: image: bbquerre/oracle-forms-14c:latest

# Start services
docker-compose up -d
```

**Note**: Docker Hub oracle-forms image still requires `./Oracle/` folder mounted

## Environment Variables

Current paths (defined in `.env` and docker-compose.yml):

```bash
# Oracle paths
ORACLE_BASE=/u01/app/oracle
ORACLE_HOME=/u01/app/oracle/middleware/fmw
JAVA_HOME=/u01/app/oracle/middleware/jdk17
MW_HOME=/u01/app/oracle/middleware
DOMAIN_HOME=/u01/app/oracle/middleware/fmw/user_projects/domains/base_domain

# Port configuration
VNC_PORT=5901
ADMIN_PORT=7001
FORMS_PORT=9001
REPORTS_PORT=9002      # Maps to container port 9012
WLS_PORT1=5556
WLS_PORT2=5557
DB_PORT=1521

# Resource limits
MEM_LIMIT=12g
MEM_RESERVATION=8g
CPUS=4
SHM_SIZE=2gb

# Database configuration
DB_PASSWORD=Oracle123
DB_APP_USER=rcu_user
DB_APP_PASSWORD=Oracle123
DB_SERVICE=FREEPDB1

# WebLogic credentials
WLS_USER=weblogic
WLS_PW=Oracle123

# Docker Hub username
DOCKERHUB_USERNAME=bbquerre
```

## Port Mapping

| Service | Container Port | Host Port | Purpose |
|---------|---------------|-----------|---------|
| VNC | 5901 | 5901 | Remote desktop access |
| WebLogic Admin | 7001 | 7001 | Admin Console |
| Forms Server | 9001 | 9001 | Forms application |
| Reports Server | 9012 | 9002 | Reports application |
| Oracle DB | 1521 | 1521 | Database connection |
| WebLogic | 5556, 5557 | 5556, 5557 | Additional WLS ports |

## Service Access

**VNC Access**:
```
vnc://localhost:5901
Password: Oracle123
```

**Web Services**:
- WebLogic Console: http://localhost:7001/console
- Enterprise Manager: http://localhost:7001/em
- Forms: http://localhost:9001/forms/frmservlet
- Reports: http://localhost:9002/reports/rwservlet

**Database Connection**:
```
Host: localhost
Port: 1521
Service: FREEPDB1
User: rcu_user
Password: Oracle123
```

**Credentials**:
- WebLogic: `weblogic / Oracle123`
- Database SYS: `Oracle123` (as sysdba)
- Database App: `rcu_user / Oracle123`
- VNC: `Oracle123`

## Auto-Start System

The `entrypoint.sh` script handles automatic service startup:

1. Starts VNC server as oracle user
2. Checks `AUTO_START_SERVICES` environment variable
3. If enabled, executes `startAllServices.sh`:
   - Starts NodeManager
   - Starts AdminServer (WebLogic)
   - Waits 30 seconds
   - Starts WLS_FORMS managed server
   - Starts WLS_REPORTS managed server
4. Tails logs to keep container alive

**Startup time**: 5-8 minutes for complete initialization

## Docker Images

### oracle-forms-14c:latest (5.03 GB)
- Oracle Linux 8 + XFCE + VNC
- WebLogic environment configured
- **Requires**: ./Oracle folder mounted at runtime
- **Contains**: OS, desktop, WebLogic setup

### bbquerre/oracle-db-with-rcu:latest (1.5 GB compressed, 7.6 GB extracted)
- Oracle 23c Free Database
- **Includes**: RCU schemas baked in (STB, OPSS, IAU, IAU_VIEWER, IAU_APPEND, MDS)
- **Self-contained**: No volume needed
- Ready for immediate use

## Development Workflow

### Making Changes to Oracle Configuration

1. Services are running with `./Oracle` mounted
2. Make changes to files in `./Oracle/` on host
3. Changes are immediately available in container
4. Restart services if needed:
   ```bash
   docker exec oracle-forms-14c sh -c "su - oracle -c 'stopAllServices.sh && startAllServices.sh'"
   ```

### Building Custom Database Image

If you modify the database and want to create a new image:

```bash
# Export current database volume
mkdir -p db_data
docker run --rm -v oracle_form_14c_oracle_db_data:/source \
  -v $(pwd)/db_data:/backup alpine \
  sh -c "cd /source && tar czf /backup/rcu_data.tar.gz ."

# Build new image
docker build -f Dockerfile.db-rcu -t bbquerre/oracle-db-with-rcu:latest .

# Push to Docker Hub
docker push bbquerre/oracle-db-with-rcu:latest
```

## User Management

- **oracle** user (uid: 54321, gid: 54321): Runs all Oracle services
- **oinstall** group (gid: 54321): Oracle installation group
- **dba** group (gid: 54322): Database administration group
- Container runs as root, switches to oracle for services

## Known Limitations

1. **Oracle Folder Not Baked In**: The oracle-forms image cannot bake the `./Oracle` folder due to symlink issues with `Oracle/fmw/lib/cobsqlintf.o` during Docker build. Current workaround: mount the folder at runtime.

2. **No Nginx**: Nginx reverse proxy was removed from the setup. All services accessed directly via ports.

3. **Database Volume**: While RCU data is baked into the image, any runtime changes to the database are lost when container restarts (unless you uncomment the volume mount in docker-compose.yml).

## Troubleshooting

See [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for detailed troubleshooting steps.

### Quick Checks

```bash
# Check container status
docker-compose ps

# View logs
docker logs -f oracle-forms-14c
docker logs -f oracle-db

# Check running processes
docker exec oracle-forms-14c ps aux | grep java

# Check AdminServer status
docker exec oracle-forms-14c curl -s http://localhost:7001/console

# Restart services
docker-compose restart oracle-forms-14c
```

## Important Notes for Claude

- Always create new `.md` files in `/docs/` folder (except README.md and CLAUDE.md)
- Current setup uses Oracle folder mounted from host
- Database image has RCU baked in - no volume needed
- Default domain name is `base_domain` (not `forms_domain`)
- Services take 5-8 minutes to fully start
- Never remove `.gitignore` entries for `Oracle/` and `db_data/`
