wa#!/bin/bash

# Initialize Host Directories Script
# This script populates empty host directories with Oracle configuration files
# Run this after first build or when host directories are empty

echo "🔧 Initializing Oracle Forms & Reports 14c host directories..."

# Create directory structure
mkdir -p tns_admin/samples
mkdir -p reports_config/ReportsServer
mkdir -p reports_config/ReportsBridge
mkdir -p reports_config/ReportsTools
mkdir -p reports_source
mkdir -p forms_source
mkdir -p applications/forms
mkdir -p applications/reports
mkdir -p applications/resources
mkdir -p oracle_domain_data
mkdir -p oracle_logs

echo "📁 Created directory structure"

# Populate TNS Admin if empty
if [ ! -f "tns_admin/tnsnames.ora" ]; then
    echo "📋 Creating TNS configuration files..."

    cat > tns_admin/tnsnames.ora << 'EOF'
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

# Example local Oracle Express Edition connection:
# XE =
#   (DESCRIPTION =
#     (ADDRESS = (PROTOCOL = TCP)(HOST = localhost)(PORT = 1521))
#     (CONNECT_DATA =
#       (SERVER = DEDICATED)
#       (SERVICE_NAME = XE)
#     )
#   )
EOF

    cat > tns_admin/sqlnet.ora << 'EOF'
# SQL*Net Configuration for Oracle Forms & Reports 14c
NAMES.DIRECTORY_PATH=(TNSNAMES, EZCONNECT)
SQLNET.AUTHENTICATION_SERVICES=(NTS)
SQLNET.INBOUND_CONNECT_TIMEOUT=60
SQLNET.RECV_TIMEOUT=30
SQLNET.SEND_TIMEOUT=30
DIAG_ADR_ENABLED=OFF
EOF

    cat > tns_admin/shrept.lst << 'EOF'
# This file is used by Reports to resolve server names
# Add your report server entries here
# Format: server_name:host:port
# Example: rep_server:localhost:14021
EOF
fi

# Populate Reports Config if empty
if [ ! -f "reports_config/rwservlet.properties" ]; then
    echo "📊 Creating Reports configuration files..."

    cat > reports_config/rwservlet.properties << 'EOF'
# Reports Servlet Configuration
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
EOF

    cat > reports_config/cgicmd.dat << 'EOF'
# CGI Command Configuration for Reports
# This file controls which commands are allowed to run
# Security: Only allow specific commands
rwservlet: /u01/app/oracle/product/fmw14.1.2.0/bin/rwservlet
rwrun: /u01/app/oracle/product/fmw14.1.2.0/bin/rwrun
rwbuilder: /u01/app/oracle/product/fmw14.1.2.0/bin/rwbuilder
EOF

    cat > reports_config/rwnetwork.conf << 'EOF'
# Reports Network Configuration
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
EOF
fi

# Create README files
echo "📖 Creating documentation..."

cat > forms_source/README.md << 'EOF'
# Forms Source Directory

Place your Oracle Forms source files (.fmb, .rdf) here for compilation.

## Compilation Examples:
```bash
# Compile a form
docker exec -it oracle-forms-14c frmcmp module=/u01/app/oracle/forms_source/myform.fmb userid=user/pass@db

# Batch compile all forms
docker exec -it oracle-forms-14c frmcmp_batch module_type=form module=/u01/app/oracle/forms_source/*.fmb userid=user/pass@db
```
EOF

cat > reports_source/README.md << 'EOF'
# Reports Source Directory

Place your Oracle Reports source files (.rdf) here for compilation.

## Compilation Examples:
```bash
# Convert RDF to REP
docker exec -it oracle-forms-14c rwconverter source=/u01/app/oracle/reports_source/myreport.rdf stype=rdffile dtype=repfile dest=/u01/app/oracle/reports_source/myreport.rep

# Run report
docker exec -it oracle-forms-14c rwrun report=/u01/app/oracle/reports_source/myreport.rdf userid=user/pass@db destype=file desname=/tmp/output.pdf desformat=pdf
```
EOF

echo "✅ Host directories initialized successfully!"
echo ""
echo "📋 Directory structure created:"
echo "   📁 tns_admin/          - Database connection configuration"
echo "   📁 reports_config/     - Reports server configuration"
echo "   📁 reports_source/     - Reports source files (.rdf)"
echo "   📁 forms_source/       - Forms source files (.fmb)"
echo "   📁 applications/       - Compiled applications (.fmx, .rep)"
echo "   📁 oracle_domain_data/ - WebLogic domain persistence"
echo "   📁 oracle_logs/        - Application logs"
echo ""
echo "🚀 Ready to start Docker Compose!"
echo "   Run: docker-compose up -d"