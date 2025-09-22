# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

**For general users and deployment information, see [README.md](README.md)**

## Overview

This is a Docker-based Oracle Forms & Reports 14c deployment project. The repository contains everything needed to build and run Oracle Forms and Reports 14c in a containerized environment using Oracle Linux 8.

**Repository**: https://github.com/erikbong/oracle-form14.git

## Documentation Structure

- **[README.md](README.md)**: Complete user guide with quick start, deployment options, troubleshooting
- **[CLAUDE.md](CLAUDE.md)**: This file - Technical guidance for Claude Code development
- **[.env.example](.env.example)**: Environment configuration template
- **[docker-compose.yml](docker-compose.yml)**: Complete deployment configuration
- **[nginx.conf](nginx.conf)**: Reverse proxy configuration

## Architecture

- **Base Image**: Oracle Linux 8 Slim
- **Oracle FMW Version**: 14.1.2.0 (Fusion Middleware Infrastructure + Forms & Reports)
- **Java Version**: Oracle JDK 17 (primary) with OpenJDK 11 fallback
- **WebLogic Domain**: `forms_domain` with AdminServer and managed servers

### Key Components

1. **Infrastructure Layer**: WebLogic Server + Java Required Files (JRF)
2. **Forms Server**: Managed server on port 9001
3. **Reports Server**: Managed server on port 9002
4. **Admin Server**: WebLogic admin console on port 7001

### Directory Structure

- `/install/` - Oracle installer binaries (FMW Infrastructure, Forms & Reports, JDK)
- `/scripts/` - Shell scripts and WLST domain creation scripts
- `/response/` - Silent installation response files
- `Dockerfile` - Multi-stage container build definition

## Container Build and Deployment

### Using Docker Compose (Recommended)

Build and start the complete stack:
```bash
docker-compose up -d
```

Build and start with nginx reverse proxy:
```bash
docker-compose --profile proxy up -d
```

Stop the services:
```bash
docker-compose down
```

Stop and remove volumes (⚠️ this will delete persisted data):
```bash
docker-compose down -v
```

### Using Docker Directly

Build the container:
```bash
docker build -t oracle-forms-14c .
```

Run the container:
```bash
docker run -d -p 7001:7001 -p 9001:9001 -p 9002:9002 oracle-forms-14c
```

**Important Notes**:
- The build requires Oracle installation files in the `install/` directory and takes 10-15 minutes
- Container startup takes 2-3 minutes to initialize all services
- Default admin credentials: `weblogic/Oracle123` (change in production)

### Port Mapping
- **7001**: WebLogic Admin Server (console at http://localhost:7001/console)
- **9001**: Forms Server
- **9002**: Reports Server
- **5556/5557**: Additional WebLogic ports
- **80** (with proxy): Nginx reverse proxy with path-based routing

### Service Access

**Direct Access:**
- WebLogic Console: http://localhost:7001/console
- Forms Service: http://localhost:9001
- Reports Service: http://localhost:9002

**With Nginx Proxy (using --profile proxy):**
- Admin Console: http://admin.localhost or http://localhost/console
- Forms: http://forms.localhost or http://localhost/forms
- Reports: http://reports.localhost or http://localhost/reports

### Docker Compose Features

- **Persistent Data**: Domain data and logs are stored in Docker volumes
- **Health Checks**: Automatic health monitoring with WebLogic console endpoint
- **Resource Limits**: Memory and CPU limits configured for stability
- **Restart Policy**: Automatic restart unless manually stopped
- **Logging**: Structured logging with rotation
- **Optional Proxy**: Nginx reverse proxy with profile-based activation

## Key Scripts

### `/scripts/startAll.sh`
Main container startup script that:
1. Starts NodeManager in background
2. Starts AdminServer (WebLogic)
3. Starts Forms and Reports managed servers
4. Tails AdminServer logs to keep container alive

### `/scripts/createDomain.py`
WLST (WebLogic Scripting Tool) script that creates the WebLogic domain with:
- AdminServer on port 7001
- forms_server1 managed server on port 9001
- reports_server1 managed server on port 9002
- Default credentials: weblogic/Oracle123

## Installation Files Required

Place these files in the `/install/` directory before building:
- `fmw_14.1.2.0.0_infrastructure.jar` - WebLogic + JRF infrastructure
- `fmw_14.1.2.0.0_fr_linux64.bin` - Forms & Reports binaries
- `jdk-17.0.12_linux-x64_bin.tar.gz` - Oracle JDK 17

## Environment Variables

- `ORACLE_HOME`: `/u01/app/oracle/product/fmw14.1.2.0`
- `DOMAIN_HOME`: `/u01/app/oracle/config/domains/forms_domain`
- `ORACLE_JDK_HOME`: `/u01/app/oracle/product/jdk17`
- `JAVA_HOME`: Points to Oracle JDK 17
- Port variables: `ADMIN_PORT`, `FORMS_PORT`, `REPORTS_PORT`

## Docker Compose Configuration

The `docker-compose.yml` file provides a complete deployment configuration with:

### Services
- **oracle-forms**: Main Oracle Forms & Reports container
- **nginx** (optional): Reverse proxy for better external access

### Volumes
- `oracle_domain_data`: Persists WebLogic domain configuration
- `oracle_logs`: Persists application and server logs

### Configuration Options
```yaml
# Override default settings by creating docker-compose.override.yml
version: '3.8'
services:
  oracle-forms:
    environment:
      - ADMIN_PASSWORD=YourSecurePassword
      - JAVA_OPTIONS=-Xmx4096m -Xms2048m
    ports:
      - "8001:7001"  # Change external port
```

## User Management

- **Oracle user** (uid: 54321, gid: 54321): Runs Oracle services
- **oinstall group**: Oracle installation group
- Container switches between root and oracle user during build phases

## Development Notes

- The Dockerfile includes extensive debugging output for troubleshooting installation issues
- All scripts are made executable during build
- Silent installation is used with response files for unattended deployment
- Domain creation happens during container build, not runtime

## Troubleshooting

### Common Issues and Solutions

1. **Missing `gzip` package**: Ensure `gzip` is included in the package installation list (already fixed in current Dockerfile)

2. **Oracle installation fails**: Check that the correct installation parameters are used:
   - Use `-ignoreSysPrereqs` (not `-ignorePrereq`)
   - Ensure response files have correct ORACLE_HOME paths

3. **Domain creation fails**: Verify WLST script syntax and ensure proper navigation between configuration sections

4. **Container startup fails**: Check that domain permissions are correctly set for the oracle user

### Build Issues Fixed

- Added missing `gzip` package for JDK extraction
- Corrected Oracle installer parameter from `-ignorePrereq` to `-ignoreSysPrereqs`
- Fixed WLST domain creation script to properly navigate configuration tree
- Added domain directory creation and permission management