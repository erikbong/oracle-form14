# Oracle Reports 14c Configuration Guide

Complete guide for configuring Oracle Reports Server, servlet, and security settings in the Docker environment.

## 📁 **Configuration File Locations**

```
reports_config/                    # Host directory (editable)
├── rwservlet.properties          # Reports Servlet configuration
├── cgicmd.dat                    # CGI security configuration
├── rwnetwork.conf                # Network settings
├── reports.conf                  # Main Reports configuration
├── jdbcpds.conf                  # JDBC data sources
├── jazn-data.xml                 # Security configuration
└── ReportsServer/                # Server-specific configs
```

## ⚙️ **Key Configuration Files**

### **1. rwservlet.properties** - Reports Servlet Configuration

```properties
# Default destination type
desttype=cache
# Default output format
desformat=pdf
# Maximum cache size (in MB)
cacheSize=100
# Reports server name
server=rep_server
# Enable parameter form
paramform=yes
# Connection timeout (seconds)
timeout=60
# Maximum concurrent users
maxUsers=50
```

### **2. cgicmd.dat** - CGI Security Configuration

```bash
# Security: Only allow specific commands
# Format: command_name: command_path
rwservlet: /u01/app/oracle/product/fmw14.1.2.0/bin/rwservlet
rwrun: /u01/app/oracle/product/fmw14.1.2.0/bin/rwrun
rwbuilder: /u01/app/oracle/product/fmw14.1.2.0/bin/rwbuilder
rwconverter: /u01/app/oracle/product/fmw14.1.2.0/bin/rwconverter

# Restrict dangerous commands (SECURITY CRITICAL)
# Never allow: rm, del, format, fdisk, etc.
```

### **3. rwnetwork.conf** - Network Configuration

```ini
[connection]
protocol=tcp
host=localhost
port=14021

[cache]
directory=/tmp/reports_cache
cleanup_interval=3600
max_size=100

[security]
enable_ssl=false
max_connections=50
allowed_hosts=localhost,127.0.0.1
```

### **4. jdbcpds.conf** - Database Configuration

```xml
<jdbcpds>
  <datasource name="default">
    <property name="driverType" value="thin"/>
    <property name="serverName" value="localhost"/>
    <property name="portNumber" value="1521"/>
    <property name="databaseName" value="XE"/>
    <property name="user" value="username"/>
    <property name="password" value="password"/>
  </datasource>
</jdbcpds>
```

## 🚀 **Configuration Steps**

### **Step 1: Database Connections**

Edit `./tns_admin/tnsnames.ora` for database connections:
```sql
REPORTSDB =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = db-host)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = your-db-service)
    )
  )
```

### **Step 2: Reports Server Settings**

Edit `./reports_config/rwservlet.properties`:
```properties
# Customize for your environment
server=rep_server
desttype=cache
desformat=pdf
paramform=yes
```

### **Step 3: Security Configuration**

Edit `./reports_config/cgicmd.dat`:
```bash
# Add only commands you need
rwservlet: /u01/app/oracle/product/fmw14.1.2.0/bin/rwservlet
# Remove or comment out dangerous commands
```

### **Step 4: Apply Changes**

```bash
# Restart the container to apply configuration changes
docker-compose restart oracle-forms
```

## 📊 **Output Formats Configuration**

### **Supported Formats:**
- **PDF** - `desformat=pdf`
- **HTML** - `desformat=html` or `desformat=htmlcss`
- **RTF** - `desformat=rtf`
- **Excel** - `desformat=xlsx`
- **XML** - `desformat=xml`
- **CSV** - `desformat=delimited`

### **Destination Types:**
- **Cache** - `destype=cache` (temporary files)
- **File** - `destype=file` (permanent files)
- **Email** - `destype=mail` (email delivery)
- **Printer** - `destype=printer` (direct printing)

## 🔒 **Security Best Practices**

### **1. CGI Command Restrictions**
```bash
# Only allow necessary commands in cgicmd.dat
rwservlet: /u01/app/oracle/product/fmw14.1.2.0/bin/rwservlet

# NEVER allow these dangerous commands:
# rm: /bin/rm
# del: /bin/del
# format: /bin/format
```

### **2. Network Security**
```ini
[security]
enable_ssl=true
max_connections=10
allowed_hosts=localhost,your-app-server
deny_hosts=*
```

### **3. User Authentication**
```properties
# Enable authentication
authid=yes
# Require valid database credentials
userid_required=yes
```

## 🚨 **Troubleshooting**

### **Reports Not Running:**
```bash
# Check Reports server logs
docker exec -it oracle-forms-14c tail -f /u01/app/oracle/config/domains/forms_domain/servers/WLS_REPORTS/logs/WLS_REPORTS.log

# Check Reports service status
docker exec -it oracle-forms-14c ps aux | grep rwserver
```

### **Configuration Issues:**
```bash
# Validate configuration files
docker exec -it oracle-forms-14c rwrun -help

# Test database connection
docker exec -it oracle-forms-14c sqlplus username/password@REPORTSDB
```

### **Permission Issues:**
```bash
# Check file permissions
docker exec -it oracle-forms-14c ls -la /u01/app/oracle/product/fmw14.1.2.0/reports/conf/

# Fix permissions if needed
docker exec -it oracle-forms-14c chown -R oracle:oinstall /u01/app/oracle/product/fmw14.1.2.0/reports/conf/
```

## 📈 **Performance Tuning**

### **Cache Configuration:**
```properties
# Increase cache size for better performance
cacheSize=500
# Cleanup interval (seconds)
cleanup_interval=1800
```

### **Connection Pooling:**
```xml
<property name="initialLimit" value="5"/>
<property name="maxLimit" value="20"/>
<property name="connectionCacheProperties" value="MinLimit=2,MaxLimit=20"/>
```

## 🔗 **Testing Configuration**

### **Basic Report Test:**
```bash
# Test via URL
http://localhost:9002/reports/rwservlet?report=test.rdf&destype=cache&desformat=pdf&userid=user/pass@REPORTSDB
```

### **Configuration Validation:**
```bash
# Check Reports servlet status
curl http://localhost:9002/reports/rwservlet
```

## 📋 **Configuration Checklist**

- [ ] Database connections configured in `tnsnames.ora`
- [ ] Reports servlet configured in `rwservlet.properties`
- [ ] Security settings configured in `cgicmd.dat`
- [ ] Network settings configured in `rwnetwork.conf`
- [ ] Output formats and destinations defined
- [ ] Authentication and authorization configured
- [ ] Performance settings optimized
- [ ] Security restrictions in place
- [ ] Configuration tested and validated