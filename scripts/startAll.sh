#!/bin/bash

DOMAIN_HOME=/u01/app/oracle/config/domains/forms_domain
ORACLE_HOME=/u01/app/oracle/product/fmw14.1.2.0

echo "Starting Oracle Forms & Reports 14c services..."

# Function to populate host directories with Oracle configuration files
populate_host_directories() {
    echo "Checking and populating host directories with Oracle configuration files..."

    # Check if TNS admin directory is empty and populate it
    if [ ! -f "$ORACLE_HOME/network/admin/shrept.lst" ]; then
        echo "Populating TNS admin directory..."
        mkdir -p "$ORACLE_HOME/network/admin/samples"

        # Create shrept.lst file
        cat > "$ORACLE_HOME/network/admin/shrept.lst" << 'EOF'
# This file is used by Reports to resolve server names
# Add your report server entries here
# Format: server_name:host:port
# Example: rep_server:localhost:14021
EOF

        # Copy sample tnsnames.ora if it doesn't exist
        if [ ! -f "$ORACLE_HOME/network/admin/tnsnames.ora" ]; then
            cat > "$ORACLE_HOME/network/admin/tnsnames.ora" << 'EOF'
# TNS Names Configuration for Oracle Forms & Reports 14c
# Add your database connection entries here

# Example database connection entry:
# MYDB =
#   (DESCRIPTION =
#     (ADDRESS = (PROTOCOL = TCP)(HOST = your-db-host)(PORT = 1521))
#     (CONNECT_DATA =
#       (SERVER = DEDICATED)
#       (SERVICE_NAME = your-service-name)
#     )
#   )
EOF
        fi

        # Create sqlnet.ora if it doesn't exist
        if [ ! -f "$ORACLE_HOME/network/admin/sqlnet.ora" ]; then
            cat > "$ORACLE_HOME/network/admin/sqlnet.ora" << 'EOF'
# SQL*Net Configuration for Oracle Forms & Reports 14c
NAMES.DIRECTORY_PATH=(TNSNAMES, EZCONNECT)
SQLNET.AUTHENTICATION_SERVICES=(NTS)
SQLNET.INBOUND_CONNECT_TIMEOUT=60
DIAG_ADR_ENABLED=OFF
EOF
        fi
    fi

    # Ensure proper ownership
    chown -R oracle:oinstall "$ORACLE_HOME/network/admin"
    chmod -R 755 "$ORACLE_HOME/network/admin"

    # Check if Reports config directory is empty and populate it
    if [ ! -f "$ORACLE_HOME/reports/conf/cgicmd.dat" ]; then
        echo "Populating Reports configuration directory..."
        mkdir -p "$ORACLE_HOME/reports/conf"

        # Create essential Reports configuration files
        cat > "$ORACLE_HOME/reports/conf/rwservlet.properties" << 'EOF'
# Reports Servlet Configuration
# Default destination type
desttype=cache
# Default output format
desformat=pdf
# Maximum cache size (in MB)
cacheSize=100
# Reports server name
server=rep_server
EOF

        cat > "$ORACLE_HOME/reports/conf/cgicmd.dat" << 'EOF'
# CGI Command Configuration for Reports
# This file controls which commands are allowed to run
# Add your allowed commands here
# Format: command_name: command_path
rwservlet: /u01/app/oracle/product/fmw14.1.2.0/bin/rwservlet
EOF

        cat > "$ORACLE_HOME/reports/conf/rwnetwork.conf" << 'EOF'
# Reports Network Configuration
# Default connection settings
[connection]
protocol=tcp
host=localhost
port=14021

[cache]
directory=/tmp/reports_cache
cleanup_interval=3600
max_size=100
EOF

        # Ensure proper ownership for Reports config
        chown -R oracle:oinstall "$ORACLE_HOME/reports/conf"
        chmod -R 755 "$ORACLE_HOME/reports/conf"
    fi
}

# Populate host directories if needed
populate_host_directories

# Check if domain exists, create if not
if [ ! -d "$DOMAIN_HOME" ]; then
    echo "Domain not found. Creating domain..."
    mkdir -p /u01/app/oracle/config/domains
    cd /u01/app/oracle/config/domains
    $ORACLE_HOME/oracle_common/common/bin/wlst.sh /scripts/createDomain.py
    chown -R oracle:oinstall /u01/app/oracle/config
fi

# Start NodeManager
echo "Starting NodeManager..."
nohup $DOMAIN_HOME/bin/startNodeManager.sh > /tmp/nodemanager.log 2>&1 &

sleep 15

# Start AdminServer
echo "Starting AdminServer..."
nohup $DOMAIN_HOME/bin/startWebLogic.sh > /tmp/adminserver.log 2>&1 &

# Wait for AdminServer to be ready
echo "Waiting for AdminServer to start..."
for i in {1..30}; do
    if grep -q "Server state changed to RUNNING" /tmp/adminserver.log 2>/dev/null; then
        echo "AdminServer is running!"
        break
    fi
    sleep 10
    echo "Waiting... ($i/30)"
done

# Enable Hosted WebLogic Remote Console
echo "Enabling Hosted WebLogic Remote Console..."
sleep 30  # Give AdminServer more time to fully initialize
$ORACLE_HOME/oracle_common/common/bin/wlst.sh /scripts/enableHostedConsole.py || echo "Console enable failed - will be available after manual setup"

# Create boot identity files for managed servers
echo "Creating boot identity files for managed servers..."
mkdir -p $DOMAIN_HOME/servers/WLS_FORMS/security
mkdir -p $DOMAIN_HOME/servers/WLS_REPORTS/security

echo "username=weblogic" > $DOMAIN_HOME/servers/WLS_FORMS/security/boot.properties
echo "password=Oracle123" >> $DOMAIN_HOME/servers/WLS_FORMS/security/boot.properties

echo "username=weblogic" > $DOMAIN_HOME/servers/WLS_REPORTS/security/boot.properties
echo "password=Oracle123" >> $DOMAIN_HOME/servers/WLS_REPORTS/security/boot.properties

# Start Forms Server (WLS_FORMS)
echo "Starting Forms Server (WLS_FORMS)..."
nohup $DOMAIN_HOME/bin/startManagedWebLogic.sh WLS_FORMS http://localhost:7001 > /tmp/forms.log 2>&1 &

sleep 10

# Start Reports Server (WLS_REPORTS)
echo "Starting Reports Server (WLS_REPORTS)..."
nohup $DOMAIN_HOME/bin/startManagedWebLogic.sh WLS_REPORTS http://localhost:7001 > /tmp/reports.log 2>&1 &

echo "All services started. Monitoring logs..."
echo "Access WebLogic Console at: http://localhost:7001/weblogic/remote-console/"
echo "Credentials: weblogic/Oracle123"

# Keep container alive and show logs
tail -f $DOMAIN_HOME/servers/AdminServer/logs/AdminServer.log