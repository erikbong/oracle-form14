#!/usr/bin/env python
# WLST script to configure Reports Server security with writeable folders

import sys
import os

# Connect to AdminServer
connect('weblogic', 'Oracle123', 't3://localhost:7001')

# Navigate to ReportsServerComponent
try:
    edit()
    startEdit()

    # Navigate to the Reports Server component
    cd('/ReportsServerComponent/ReportsServer')

    # Configure security settings with writeable folders
    print('Configuring Reports Server security...')

    # Set writeable folders (cache and temp directories)
    cmo.setSecurityId('rwJaznSec')
    cmo.setSecurityClass('oracle.reports.server.RWJAZNSecurity')

    # Configure writeable folders property
    writeableFolders = '/u01/app/oracle/config/domains/forms_domain/reports/cache;/tmp'
    cmo.setWriteableFolders(writeableFolders)

    print('Writeable folders configured: ' + writeableFolders)

    # Save and activate changes
    save()
    activate()

    print('Reports Server security configuration completed successfully!')
    print('Please restart WLS_REPORTS managed server for changes to take effect.')

except Exception, e:
    print('Error configuring Reports Server security:')
    print(str(e))
    cancelEdit('y')
    sys.exit(1)

disconnect()
