#!/bin/bash
# Script to increase Reports Server memory
# This script modifies the setDomainEnv.sh to increase heap memory for Reports Server

DOMAIN_HOME=/u01/app/oracle/config/domains/forms_domain
SET_DOMAIN_ENV="${DOMAIN_HOME}/bin/setDomainEnv.sh"

echo "Backing up setDomainEnv.sh..."
cp "${SET_DOMAIN_ENV}" "${SET_DOMAIN_ENV}.backup"

echo "Updating memory settings in setDomainEnv.sh..."
# Change 512m to 2048m for maximum heap
sed -i 's/WLS_MEM_ARGS_64BIT="-Xms512m -Xmx512m"/WLS_MEM_ARGS_64BIT="-Xms1024m -Xmx2048m"/g' "${SET_DOMAIN_ENV}"
sed -i 's/WLS_MEM_ARGS_32BIT="-Xms512m -Xmx512m"/WLS_MEM_ARGS_32BIT="-Xms1024m -Xmx2048m"/g' "${SET_DOMAIN_ENV}"

# Also update the smaller settings
sed -i 's/WLS_MEM_ARGS_64BIT="-Xms256m -Xmx512m"/WLS_MEM_ARGS_64BIT="-Xms1024m -Xmx2048m"/g' "${SET_DOMAIN_ENV}"
sed -i 's/WLS_MEM_ARGS_32BIT="-Xms256m -Xmx512m"/WLS_MEM_ARGS_32BIT="-Xms1024m -Xmx2048m"/g' "${SET_DOMAIN_ENV}"

echo "Memory settings updated successfully!"
echo "New settings:"
grep "WLS_MEM_ARGS" "${SET_DOMAIN_ENV}" | grep -v "^#" | head -4

echo ""
echo "Please restart the Reports Server for changes to take effect:"
echo "  docker exec oracle-forms-14c /u01/app/oracle/config/domains/forms_domain/bin/stopManagedWebLogic.sh reports_server1"
echo "  docker exec oracle-forms-14c /u01/app/oracle/config/domains/forms_domain/bin/startManagedWebLogic.sh reports_server1"
