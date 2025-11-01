#!/usr/bin/env python
"""
WLST Script to extend existing domain with Reports configuration
This adds the Reports application deployment to WLS_REPORTS
"""

print('Extending domain to add Reports configuration...')

# Read existing domain
readDomain('/u01/app/oracle/config/domains/forms_domain')

print('Domain read successfully')

# Add Reports application template to extend domain
print('Adding Reports application template...')
try:
    addTemplate('/u01/app/oracle/product/fmw14.1.2.0/reports/common/templates/wls/oracle.reports_app_template.jar')
    print('Reports application template added successfully')
except Exception as e:
    print('Failed to add Reports template: ' + str(e))

# Assign Reports server group to WLS_REPORTS
print('Assigning REPORTS-APP-SERVERS server group to WLS_REPORTS...')
cd('/')
try:
    assign('Server', 'WLS_REPORTS', 'ServerGroup', 'REPORTS-APP-SERVERS')
    print('Server group assigned successfully')
except Exception as e:
    print('Failed to assign server group: ' + str(e))

# Update domain
print('Updating domain...')
updateDomain()
closeDomain()

print('Domain extension completed!')
print('WLS_REPORTS should now have Reports application deployed')
exit()
