#!/bin/bash
#Fix Reports Server security configuration to allow cache writes

CONFIG_FILE="/u01/app/oracle/config/domains/forms_domain/config/fmwconfig/servers/WLS_REPORTS/applications/reports_14.1.2/configuration/rwserver.conf"

echo "Fixing Reports Server security configuration..."

# Add security configuration with writeable folders after the commented security section
cat > /tmp/rwserver_security.xml << 'EOF'

   <security id="rwJaznSec" class="oracle.reports.server.RWJAZNSecurity">
      <property name="writeableFolders" value="/u01/app/oracle/config/domains/forms_domain/reports/cache;/tmp;/u01/app/oracle/reports_source"/>
   </security>
EOF

# Insert the security configuration after the commented security section
# Find the line with "<!-- Security disabled for testing -->" and add the security config after it
sed -i '/<!-- Security disabled for testing -->/r /tmp/rwserver_security.xml' "$CONFIG_FILE"

echo "Security configuration added to rwserver.conf"
echo "Writeable folders configured: /u01/app/oracle/config/domains/forms_domain/reports/cache, /tmp, /u01/app/oracle/reports_source"

# Display the updated configuration
echo ""
echo "Updated rwserver.conf security section:"
grep -A 3 '<security' "$CONFIG_FILE" | head -10

echo ""
echo "Configuration complete! Reports Server will now have write access to cache directory."
