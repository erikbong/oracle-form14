#!/bin/bash

DOMAIN_HOME=/u01/app/oracle/config/domains/forms_domain

# Start NodeManager
nohup $DOMAIN_HOME/bin/startNodeManager.sh > /dev/null 2>&1 &

sleep 10

# Start AdminServer
nohup $DOMAIN_HOME/bin/startWebLogic.sh > /dev/null 2>&1 &

sleep 60

# Start Forms and Reports Managed Servers
nohup $DOMAIN_HOME/bin/startManagedWebLogic.sh forms_server1 > /dev/null 2>&1 &
nohup $DOMAIN_HOME/bin/startManagedWebLogic.sh reports_server1 > /dev/null 2>&1 &

# Keep container alive
tail -f $DOMAIN_HOME/servers/AdminServer/logs/AdminServer.log