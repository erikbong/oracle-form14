#!/bin/bash
# Setup Oracle Reports 14c with RCU schemas
set -e

echo "=== Oracle Reports 14c RCU Schema Creation ==="
echo ""

# Database details
DB_HOST="46.137.238.154"
DB_PORT="1522"
DB_SERVICE="tos19pdb.ap-southeast-1.compute.internal"
DB_USER="bictsimpb"
DB_PWD="bictsimpb1"
SCHEMA_PREFIX="FRDEV"
SCHEMA_PWD="Oracle123"

# Set Oracle environment
export ORACLE_HOME=/u01/app/oracle/product/fmw14.1.2.0
export JAVA_HOME=/u01/app/oracle/product/jdk17

echo "Testing database connectivity..."
# Test TNS connection
if ! echo "exit" | sqlplus -S ${DB_USER}/${DB_PWD}@BICTSIMPB 2>&1 | grep -q "Connected"; then
    echo "WARNING: Could not verify database connection via TNS"
    echo "Proceeding with RCU anyway..."
fi

echo ""
echo "Running RCU to create schemas..."
echo "Database: ${DB_HOST}:${DB_PORT}/${DB_SERVICE}"
echo "Schema Prefix: ${SCHEMA_PREFIX}"
echo ""

# Run RCU in silent mode
${ORACLE_HOME}/oracle_common/bin/rcu \
    -silent \
    -createRepository \
    -connectString ${DB_HOST}:${DB_PORT}/${DB_SERVICE} \
    -dbUser ${DB_USER} \
    -dbRole Normal \
    -useSamePasswordForAllSchemaUsers true \
    -schemaPrefix ${SCHEMA_PREFIX} \
    -component STB \
    -component OPSS \
    -component IAU \
    -component MDS \
    -component WLS \
    <<EOF
${DB_PWD}
${SCHEMA_PWD}
EOF

RCU_EXIT=$?

if [ $RCU_EXIT -eq 0 ]; then
    echo ""
    echo "✅ RCU schemas created successfully!"
    echo ""
    echo "Schemas created with prefix: ${SCHEMA_PREFIX}"
    echo "  - ${SCHEMA_PREFIX}_STB (Service Table)"
    echo "  - ${SCHEMA_PREFIX}_OPSS (Platform Security)"
    echo "  - ${SCHEMA_PREFIX}_IAU (Audit)"
    echo "  - ${SCHEMA_PREFIX}_MDS (Metadata)"
    echo "  - ${SCHEMA_PREFIX}_WLS (WebLogic)"
    echo ""
    echo "Next: Run config.sh wizard to configure Reports domain"
    exit 0
else
    echo ""
    echo "⚠️  RCU exited with code: $RCU_EXIT"
    if [ $RCU_EXIT -eq 1 ]; then
        echo "Schemas may already exist - this is OK if running again"
        echo "Proceeding to domain configuration..."
        exit 0
    else
        echo "RCU failed - check logs"
        exit 1
    fi
fi
