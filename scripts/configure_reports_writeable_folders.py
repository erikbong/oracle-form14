#!/usr/bin/env python
# Configure Reports Server writeable folders via MBean

# Connect to Admin Server
connect('weblogic', 'Oracle123', 't3://localhost:7001')

# Navigate to the custom MBean
try:
    # Get the Reports Server MBean
    serverRuntime()
    cd('/AppRuntimeStateRuntime/AppRuntimeStateRuntime')

    # Try to access the Reports configuration MBean
    custom()
    cd('oracle.reportsApp.config')
    cd('Server: WLS_REPORTS')
    cd('Application: reports')
    cd('ReportsApp')
    cd('rwserver')

    # Try to set writeable folders
    print('Current Security configuration:')
    ls()

    # Attempt to add writeable folders configuration
    print('\nAttempting to configure writeable folders...')

    # Check if we can modify the Security attribute
    print('\nSecurity attribute value:')
    print(get('Security'))

except Exception, e:
    print('Error navigating MBean tree: ' + str(e))
    print('\nTrying alternative approach...')

    try:
        # Try direct MBean access
        from javax.management import ObjectName

        # Get MBean Server
        serverRuntime()
        mbeanServer = getMBeanServer()

        # Construct ObjectName for rwserver MBean
        objName = ObjectName('oracle.reportsApp.config:Location=WLS_REPORTS,name=rwserver,type=ReportsApp.Application=reports,ApplicationVersion=14.1.2')

        print('Attempting to access MBean: ' + str(objName))

        # Try to get Security attribute
        security = mbeanServer.getAttribute(objName, 'Security')
        print('Current Security: ' + str(security))

    except Exception, e2:
        print('Alternative approach also failed: ' + str(e2))

disconnect()
print('\nScript completed.')
