#!/bin/bash

DOMAIN_HOME=/u01/app/oracle/config/domains/forms_domain
ORACLE_HOME=/u01/app/oracle/product/fmw14.1.2.0

echo "========================================="
echo "Oracle Forms & Reports 14c Container"
echo "========================================="
echo ""
echo "Starting VNC server for GUI access..."
vncserver :1 -geometry 1280x1024 -depth 24 || echo "VNC server already running or failed to start"

echo ""
echo "========================================="
echo "VNC Connection Information:"
echo "========================================="
echo "Host: localhost:5901"
echo "Password: Oracle123"
echo ""

# Check if domain exists
if [ ! -f "$DOMAIN_HOME/config/config.xml" ]; then
    echo "========================================="
    echo "Domain not yet created!"
    echo "========================================="
    echo "To create the domain:"
    echo "1. Connect to VNC"
    echo "2. In the terminal, run:"
    echo "   cd /u01/app/oracle/product/fmw14.1.2.0/oracle_common/common/bin"
    echo "   ./config.sh"
    echo ""
    echo "3. In the Configuration Wizard:"
    echo "   - Choose: Create a new domain"
    echo "   - Domain Location: /u01/app/oracle/config/domains/forms_domain"
    echo "   - Select templates: Oracle JRF + EM + Forms + Reports"
    echo "   - Database: oracle-db:1521/FREEPDB1"
    echo "   - Schema: DEV_STB, Password: Oracle123"
    echo ""
    echo "========================================="
    echo "Container is ready. Keeping container alive..."
    echo "========================================="
    tail -f /dev/null
else
    echo "========================================="
    echo "Starting WebLogic Domain..."
    echo "========================================="

    # Start Node Manager in background
    echo "Starting Node Manager..."
    nohup $DOMAIN_HOME/bin/startNodeManager.sh > $DOMAIN_HOME/nodemanager.log 2>&1 &

    # Wait for Node Manager to start
    sleep 10

    # Start AdminServer
    echo "Starting AdminServer..."
    nohup $DOMAIN_HOME/bin/startWebLogic.sh > $DOMAIN_HOME/AdminServer.log 2>&1 &

    # Wait for AdminServer to start
    echo "Waiting for AdminServer to start (this may take 2-3 minutes)..."
    sleep 120

    # Create boot.properties for managed servers to avoid password prompts
    mkdir -p $DOMAIN_HOME/servers/WLS_FORMS/security
    mkdir -p $DOMAIN_HOME/servers/WLS_REPORTS/security

    echo "username=weblogic" > $DOMAIN_HOME/servers/WLS_FORMS/security/boot.properties
    echo "password=Oracle123" >> $DOMAIN_HOME/servers/WLS_FORMS/security/boot.properties

    echo "username=weblogic" > $DOMAIN_HOME/servers/WLS_REPORTS/security/boot.properties
    echo "password=Oracle123" >> $DOMAIN_HOME/servers/WLS_REPORTS/security/boot.properties

    # Start WLS_FORMS managed server
    echo "Starting WLS_FORMS managed server..."
    nohup $DOMAIN_HOME/bin/startManagedWebLogic.sh WLS_FORMS http://localhost:7001 > $DOMAIN_HOME/WLS_FORMS.log 2>&1 &

    # Wait a bit
    sleep 10

    # Start WLS_REPORTS managed server
    echo "Starting WLS_REPORTS managed server..."
    nohup $DOMAIN_HOME/bin/startManagedWebLogic.sh WLS_REPORTS http://localhost:7001 > $DOMAIN_HOME/WLS_REPORTS.log 2>&1 &

    echo ""
    echo "========================================="
    echo "All servers started!"
    echo "========================================="
    echo "WebLogic Admin Console: http://localhost:7001/console"
    echo "Forms: http://localhost:9001/forms/frmservlet"
    echo "Reports: http://localhost:9002/reports/rwservlet"
    echo ""
    echo "Credentials: weblogic/Oracle123"
    echo "========================================="

    # Tail the AdminServer log to keep container alive
    tail -f $DOMAIN_HOME/AdminServer.log
fi
