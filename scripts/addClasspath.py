#!/usr/bin/env python
"""
WLST Script to add classpath to WLS_REPORTS server
"""

print('Adding classpath to WLS_REPORTS server...')

# Connect to AdminServer
print('Connecting to AdminServer...')
connect('weblogic', 'Oracle123', 't3://localhost:7001')

# Start editing
print('Starting edit session...')
edit()
startEdit()

# Configure classpath
print('Configuring classpath for WLS_REPORTS...')
oracle_home = '/u01/app/oracle/product/fmw14.1.2.0'
reports_classpath = oracle_home + '/oracle_common/modules/oracle.jmx/jmxframework.jar:' + \
                    oracle_home + '/oracle_common/modules/oracle.jmx/jmxspi.jar:' + \
                    oracle_home + '/oracle_common/modules/oracle.jrf/jrf-api.jar:' + \
                    oracle_home + '/oracle_common/modules/oracle.adf.share/adfsharembean.jar:' + \
                    oracle_home + '/oracle_common/modules/oracle.adf.share/adf-share-support.jar'

cd('/Servers/WLS_REPORTS/ServerStart/WLS_REPORTS')
set('ClassPath', reports_classpath)
print('Classpath set to: ' + reports_classpath)

# Save and activate changes
print('Saving configuration...')
save()
activate(block='true')

# Disconnect
print('Disconnecting...')
disconnect()

print('')
print('========================================')
print('Classpath Configuration Completed!')
print('========================================')
print('WLS_REPORTS must be restarted for changes to take effect')
print('')
