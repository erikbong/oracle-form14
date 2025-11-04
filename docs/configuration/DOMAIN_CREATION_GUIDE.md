# Domain Creation Guide - Oracle Forms & Reports 14c

This guide documents the process of creating the WebLogic domain with JRF, Enterprise Manager, Oracle Forms, and Oracle Reports using the Oracle Configuration Wizard via VNC.

## Overview

The domain is created **manually** using Oracle's official Configuration Wizard (`config.sh`) after the Docker container is running. This approach ensures proper configuration of all components including JRF schemas, Enterprise Manager, Forms, and Reports.

## Prerequisites

- Docker and Docker Compose installed
- VNC client installed (TigerVNC, RealVNC, TightVNC, or any VNC viewer)
- Oracle Database 23c Free running (automatically started via docker-compose)

## Step 1: Start the Containers

```bash
cd /path/to/oracle_form_14c
docker-compose up -d
```

This will start:
- `oracle-db` - Oracle Database 23c Free container
- `oracle-forms-14c` - Oracle Forms & Reports container with VNC enabled

## Step 2: Connect to VNC

The container runs a VNC server for GUI access to the Configuration Wizard.

**VNC Connection Details:**
- **Host**: `localhost:5901`
- **Password**: `Oracle123`

Open your VNC client and connect to `localhost:5901`. You'll see an xterm terminal window.

## Step 3: Launch Configuration Wizard

In the VNC terminal, run:

```bash
cd /u01/app/oracle/product/fmw14.1.2.0/oracle_common/common/bin
./config.sh
```

The Oracle Fusion Middleware Configuration Wizard will launch.

## Step 4: Configuration Wizard Steps

### 4.1 Welcome Screen
- Click **Next**

### 4.2 Create Domain
- Select: **Create a new domain**
- Domain Location: `/u01/app/oracle/config/domains/forms_domain`
- Click **Next**

**Important:** The directory must be completely empty. If it exists with files, delete it first.

### 4.3 Templates
Select the following templates (in order):
1. ☑ **Oracle JRF - 14.1.2.0.0** [oracle_common]
2. ☑ **Oracle Enterprise Manager - 14.1.2.0.0** [em]
3. ☑ **Oracle Forms - 14.1.2.0.0** [forms]
4. ☑ **Oracle Reports Application - 14.1.2.0.0** [reports]
5. ☑ **Oracle Reports Tools Component - 14.1.2.0.0** [reports]

Click **Next**

**Note:** Oracle JRF and Enterprise Manager are required for Reports to function properly.

### 4.4 Application Location
- Application Location: `/u01/app/oracle/product/fmw14.1.2.0/user_projects/applications/forms_domain`
- Click **Next**

### 4.5 Administrator Account
- Username: `weblogic`
- Password: `Oracle123`
- Confirm Password: `Oracle123`
- Click **Next**

### 4.6 Domain Mode and JDK
- Domain Mode: **Development** (recommended for easier management)
  - Production mode can be used if you need stricter security
- JDK: Select **Oracle HotSpot 17.0.12** (`/u01/app/oracle/product/jdk17`)
- Click **Next**

### 4.7 Database Configuration Type
- Select: **RCU Data**
- Click **Next**

### 4.8 JDBC Component Schema
**Database Connection Details:**
- Vendor: **Oracle**
- Driver: **Oracle's Driver (Thin) for Instance connections**
- DBMS/Service: `oracle-db:1521/FREEPDB1`
- Host Name: `oracle-db`
- Port: `1521`
- Service Name: `FREEPDB1`

**Schema Configuration:**
- Schema Owner: `DEV_STB`
- Schema Password: `Oracle123`

Click **Get RCU Configuration**

The wizard will create the following RCU schemas automatically:
- DEV_STB (Service Table)
- DEV_JRF (Java Required Files)
- DEV_OPSS (Oracle Platform Security Services)
- DEV_IAU (Audit)
- DEV_MDS (Metadata Services)
- DEV_WLS (WebLogic Services)
- DEV_UMS (User Messaging Service)

Wait for schema creation to complete, then click **Next**

### 4.9 JDBC Component Schema Test
The wizard will test all database connections. Verify all connections show **Success**, then click **Next**

### 4.10 Advanced Configuration
- Optionally configure: Administration Server, Node Manager, Managed Servers, etc.
- For default configuration, just click **Next**

### 4.11 Node Manager
- Node Manager Type: **Per Domain Default Location**
- Username: `weblogic`
- Password: `Oracle123`
- Confirm Password: `Oracle123`
- Click **Next**

### 4.12 Managed Servers
The wizard automatically creates two managed servers:
- **WLS_FORMS** - Forms server (port 9001)
- **WLS_REPORTS** - Reports server (port 9002 or 9012 depending on config)

You can adjust ports if needed. Click **Next**

### 4.13 Configuration Summary
Review all configuration settings and click **Create**

### 4.14 Domain Creation
The wizard will:
1. Create domain structure
2. Configure JRF components
3. Deploy Enterprise Manager
4. Configure Forms and Reports
5. Create RCU schemas (if not already created)

This process takes 5-10 minutes.

### 4.15 Completion
When complete, click **Finish**

## Step 5: Restart the Container

After domain creation is complete, restart the container so the startup script can detect and start the domain:

```bash
docker-compose restart oracle-forms
```

The startup script will automatically:
1. Detect the existing domain
2. Start Node Manager
3. Start AdminServer (port 7001)
4. Start WLS_FORMS managed server (port 9001)
5. Start WLS_REPORTS managed server (port 9002)

## Step 6: Verify Deployment

Wait about 3-5 minutes for all servers to start, then access:

### WebLogic Admin Console
- URL: http://localhost:7001/console
- Username: `weblogic`
- Password: `Oracle123`

### Oracle Forms
- URL: http://localhost:9001/forms/frmservlet
- Should show "Forms Servlet - Listening" page

### Oracle Reports
- URL: http://localhost:9002/reports/rwservlet
- Should show Reports servlet status page

## Troubleshooting

### VNC Connection Issues
- Ensure port 5901 is not blocked by firewall
- Try restarting the container: `docker-compose restart oracle-forms`
- Check VNC logs: `docker logs oracle-forms-14c`

### Domain Already Exists Error
The Configuration Wizard requires an empty directory. Delete the existing domain:
```bash
docker exec -u root oracle-forms-14c rm -rf /u01/app/oracle/config/domains/forms_domain
docker exec -u root oracle-forms-14c rm -rf /u01/app/oracle/product/fmw14.1.2.0/user_projects/applications/forms_domain
```

### Database Connection Failed
- Verify Oracle Database container is running: `docker ps | grep oracle-db`
- Check database is healthy: `docker logs oracle-db`
- Wait 30-60 seconds for database to fully start

### RCU Schema Creation Failed
If RCU schema creation fails during the Configuration Wizard, the wizard will stop. You need to drop any partially created schemas and retry:

```bash
# Connect to the Forms container
docker exec -it oracle-forms-14c bash

# Drop RCU schemas
cd /u01/app/oracle/product/fmw14.1.2.0/oracle_common/bin
./rcu -silent -dropRepository -databaseType ORACLE \
  -connectString oracle-db:1521/FREEPDB1 \
  -dbUser sys -dbRole sysdba \
  -schemaPrefix DEV \
  -component STB -component OPSS -component IAU -component MDS -component WLS

# Enter sys password when prompted: Oracle123
```

Then retry the Configuration Wizard.

## Data Persistence

All domain data is persisted in Docker volumes:
- `oracle_domain_data` - Domain configuration at `/u01/app/oracle/config/domains`
- `oracle_user_projects` - Applications at `/u01/app/oracle/product/fmw14.1.2.0/user_projects`
- `oracle_db_data` - Database files with RCU schemas

These volumes persist even when containers are stopped or removed (unless you use `docker-compose down -v`).

## Next Steps

After successful domain creation:
1. Review [FORMS_DEVELOPMENT_GUIDE.md](FORMS_DEVELOPMENT_GUIDE.md) for Forms development
2. Review [REPORTS_DEVELOPMENT_GUIDE.md](REPORTS_DEVELOPMENT_GUIDE.md) for Reports development
3. See [WEBLOGIC_CONSOLE_GUIDE.md](WEBLOGIC_CONSOLE_GUIDE.md) for WebLogic administration
4. Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common issues

## Summary

This manual domain creation approach using the Configuration Wizard ensures:
- ✅ Proper JRF schema creation and configuration
- ✅ Enterprise Manager deployment
- ✅ Correct Forms and Reports integration
- ✅ Full WebLogic domain with all required components
- ✅ All data persisted in Docker volumes for container restarts
