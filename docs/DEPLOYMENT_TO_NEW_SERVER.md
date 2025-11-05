# Deploying Oracle Forms & Reports 14c to a New Server

This guide walks you through deploying Oracle Forms & Reports 14c from backup to a new server.

## Prerequisites

### Server Requirements
- **OS**: Ubuntu 20.04+ / RHEL 8+ / Amazon Linux 2
- **CPU**: 4+ cores
- **RAM**: 16GB minimum (24GB recommended)
- **Disk**: 60GB+ free space
- **Docker**: 20.10+
- **Docker Compose**: v2.0+

### Required Files
1. `Oracle_backup.tar.gz` - Oracle installation backup (~4.5GB)
2. Project repository from GitHub

## Step-by-Step Deployment

### 1. Install Docker and Docker Compose

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add current user to docker group
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify installation
docker --version
docker-compose --version

# Log out and back in for group changes to take effect
```

### 2. Clone Repository

```bash
# Clone the repository
git clone https://github.com/erikbong/oracle-form14.git
cd oracle-form14
```

### 3. Extract Oracle Backup

Upload your `Oracle_backup.tar.gz` to the server, then extract:

```bash
# Extract Oracle backup (this may take several minutes)
tar xzf Oracle_backup.tar.gz

# Verify extraction
ls -la Oracle/
```

### 4. Fix Permissions

This is the **most critical step**! Run the permission fix script:

```bash
# Make the script executable
chmod +x fix-permissions.sh

# Run the permission fix script
./fix-permissions.sh
```

The script will:
- ✅ Set correct ownership (oracle user: UID 54321)
- ✅ Fix directory permissions (755)
- ✅ Fix file permissions (644 for files, 755 for executables)
- ✅ Make shell scripts executable
- ✅ Make Java binaries executable
- ✅ Make WebLogic binaries executable
- ✅ Clean VNC lock files
- ✅ Start services

### 5. Configure Environment (Optional)

```bash
# Copy environment template
cp .env.example .env

# Edit environment variables (IMPORTANT: Change passwords in production!)
nano .env

# Update the following:
# - WLS_PW=YourSecurePassword
# - DB_PASSWORD=YourSecurePassword
# - VNC_PASSWORD=YourSecurePassword
```

### 6. Pull Database Image

```bash
# Pull the pre-configured database with RCU
docker pull bbquerre/oracle-db-with-rcu:latest
```

### 7. Start Services

If you didn't run the fix-permissions script with auto-start:

```bash
# Start all services
docker-compose up -d

# Monitor logs
docker logs -f oracle-forms-14c
```

**Wait 5-8 minutes** for all services to initialize.

### 8. Verify Services

```bash
# Check container status
docker ps

# Should show:
# - oracle-forms-14c (healthy)
# - oracle-db (healthy)

# Check running services inside container
docker exec oracle-forms-14c ps aux | grep java

# Should show:
# - NodeManager
# - AdminServer
# - WLS_FORMS
# - WLS_REPORTS
```

### 9. Access Services

| Service | URL | Credentials |
|---------|-----|-------------|
| VNC Desktop | vnc://your-server-ip:5901 | Oracle123 |
| WebLogic Console | http://your-server-ip:7001/console | weblogic / Oracle123 |
| Forms | http://your-server-ip:9001/forms/frmservlet | - |
| Reports | http://your-server-ip:9002/reports/rwservlet | - |
| Database | your-server-ip:1521/FREEPDB1 | rcu_user / Oracle123 |

## Troubleshooting

### Services Not Starting

```bash
# Check logs
docker logs oracle-forms-14c

# Common issues:
# 1. Permission denied errors → Run fix-permissions.sh again
# 2. VNC lock files → Already handled by fix-permissions.sh
# 3. Logs directory permission denied → Run fix-permissions.sh
```

### NodeManager Failed to Start

```bash
# Check NodeManager logs
docker exec oracle-forms-14c cat /u01/app/oracle/middleware/logs/nodemanager.log

# If you see "Permission denied" for Java:
sudo find ./Oracle/jdk17/bin -type f -exec chmod 755 {} \;
docker-compose restart oracle-forms
```

### VNC Not Working

```bash
# Clean VNC lock files
docker-compose down
sudo rm -f ./Oracle/.X*-lock
docker-compose up -d
```

### Database Connection Issues

```bash
# Check database status
docker logs oracle-db

# Test database connection
docker exec oracle-db sqlplus rcu_user/Oracle123@//localhost:1521/FREEPDB1
```

## Firewall Configuration

If using a firewall, open these ports:

```bash
# Ubuntu/Debian (ufw)
sudo ufw allow 5901/tcp  # VNC
sudo ufw allow 7001/tcp  # WebLogic Admin
sudo ufw allow 9001/tcp  # Forms
sudo ufw allow 9002/tcp  # Reports
sudo ufw allow 1521/tcp  # Database

# RHEL/CentOS (firewalld)
sudo firewall-cmd --permanent --add-port=5901/tcp
sudo firewall-cmd --permanent --add-port=7001/tcp
sudo firewall-cmd --permanent --add-port=9001/tcp
sudo firewall-cmd --permanent --add-port=9002/tcp
sudo firewall-cmd --permanent --add-port=1521/tcp
sudo firewall-cmd --reload
```

## Cloud Provider Specific Notes

### AWS EC2

1. **Instance Type**: t3.xlarge or larger (4 vCPU, 16GB RAM minimum)
2. **Security Group**: Open ports 5901, 7001, 9001, 9002, 1521
3. **Storage**: EBS volume with at least 60GB

### Azure VM

1. **VM Size**: Standard_D4s_v3 or larger
2. **Network Security Group**: Allow inbound ports 5901, 7001, 9001, 9002, 1521
3. **Disk**: Premium SSD with 60GB+

### Google Cloud Platform

1. **Machine Type**: n1-standard-4 or larger
2. **Firewall Rules**: Allow TCP ports 5901, 7001, 9001, 9002, 1521
3. **Disk**: SSD persistent disk with 60GB+

## Production Checklist

Before going to production:

- [ ] Change all default passwords in `.env`
- [ ] Enable WebLogic production mode
- [ ] Configure SSL/TLS for WebLogic
- [ ] Set up regular backups
- [ ] Configure firewall rules
- [ ] Set up monitoring and alerts
- [ ] Review security settings in WebLogic Console
- [ ] Test all services thoroughly
- [ ] Document custom configurations

## Backup Strategy

### Backing Up Oracle Folder

```bash
# Create backup (run on working system)
cd /path/to/oracle_form_14c
tar czf Oracle_backup_$(date +%Y%m%d).tar.gz Oracle/
```

### Backing Up Database

```bash
# Export database data
mkdir -p db_backup
docker run --rm -v oracle_form_14c_oracle_db_data:/source \
  -v $(pwd)/db_backup:/backup alpine \
  sh -c "cd /source && tar czf /backup/db_backup_$(date +%Y%m%d).tar.gz ."
```

## Quick Command Reference

```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# Restart services
docker-compose restart

# View logs
docker logs -f oracle-forms-14c
docker logs -f oracle-db

# Check status
docker ps
docker stats

# Access container shell
docker exec -it oracle-forms-14c bash

# Fix permissions
./fix-permissions.sh
```

## Support

- **Documentation**: See `/docs` directory
- **Troubleshooting**: [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- **GitHub Issues**: https://github.com/erikbong/oracle-form14/issues
- **Docker Hub**:
  - Forms: https://hub.docker.com/r/bbquerre/oracle-forms-14c
  - Database: https://hub.docker.com/r/bbquerre/oracle-db-with-rcu
