#!/usr/bin/env python
"""
WLST Script to deploy Reports application to WLS_REPORTS managed server
"""

import os

print('Deploying Reports application to WLS_REPORTS...')
print('')

# Connect to AdminServer
print('Connecting to AdminServer...')
connect('weblogic', 'Oracle123', 't3://localhost:7001')

# Start editing
print('Starting edit session...')
edit()
startEdit()

# Paths to Reports files
reports_applib = '/u01/app/oracle/product/fmw14.1.2.0/reports/j2ee/oracle.reports.applib.jar'
reports_ear = '/u01/app/oracle/product/fmw14.1.2.0/reports/j2ee/reports.ear'

# Check if already deployed
print('Checking existing deployments...')
cd('/')
libraries = cmo.getLibraries()
applib_deployed = False

for lib in libraries:
    if 'oracle.reports.applib' in lib.getName():
        applib_deployed = True
        print('Reports AppLib already deployed: ' + lib.getName())
        break

# Deploy the shared library first if not already deployed
# Target both AdminServer and WLS_REPORTS to ensure classpath is available
if not applib_deployed:
    print('Deploying oracle.reports.applib shared library to all servers...')
    try:
        deploy('oracle.reports.applib', reports_applib, targets='AdminServer,WLS_REPORTS', libraryModule='true', upload='false')
        print('Reports AppLib deployed successfully')
    except Exception as e:
        print('Failed to deploy Reports AppLib: ' + str(e))
        print('Trying to deploy to WLS_REPORTS only...')
        try:
            deploy('oracle.reports.applib', reports_applib, targets='WLS_REPORTS', libraryModule='true', upload='false')
            print('Reports AppLib deployed to WLS_REPORTS')
        except Exception as e2:
            print('Failed to deploy Reports AppLib: ' + str(e2))
            cancelEdit('y')
            disconnect()
            raise Exception('AppLib deployment failed')
else:
    print('Reports AppLib is already deployed')

# Now deploy the reports application
deployments = cmo.getAppDeployments()
reports_deployed = False

for deployment in deployments:
    if deployment.getName() == 'reports':
        reports_deployed = True
        print('Reports application already deployed: ' + deployment.getName())
        break

if not reports_deployed:
    print('Deploying reports.ear...')
    try:
        deploy('reports', reports_ear, targets='WLS_REPORTS', upload='false')
        print('Reports application deployed successfully')
    except Exception as e:
        print('Failed to deploy reports application: ' + str(e))
        cancelEdit('y')
        disconnect()
        raise Exception('Reports deployment failed')
else:
    print('Reports application is already deployed, skipping...')

# Save and activate changes
print('Saving and activating configuration...')
try:
    save()
    activate(block='true')
    print('Changes activated successfully')
except Exception as e:
    print('Failed to activate changes: ' + str(e))
    cancelEdit('y')
    disconnect()
    raise Exception('Activation failed')

# Disconnect
print('Disconnecting...')
disconnect()

print('')
print('========================================')
print('Reports Deployment Completed!')
print('========================================')
print('')
print('Reports Servlet URL: http://localhost:9002/reports/rwservlet')
print('Test with: http://localhost:9002/reports/rwservlet?server=help')
print('')
print('For JSP reports:')
print('http://localhost:9002/reports/rwservlet?report=BATCH-TEMPORARY.jsp&userid=user/pass@db&desformat=pdf&destype=cache')
print('')
