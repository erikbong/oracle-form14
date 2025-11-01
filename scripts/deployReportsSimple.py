#!/usr/bin/env python
"""
WLST Script to deploy Reports application to WLS_REPORTS managed server
Simplified version with better error handling
"""

import os
import sys

print('========================================')
print('Deploying Reports Application')
print('========================================')
print('')

# Connect to AdminServer
print('Connecting to AdminServer...')
try:
    connect('weblogic', 'Oracle123', 't3://localhost:7001')
    print('Connected successfully')
except Exception as e:
    print('Failed to connect: ' + str(e))
    sys.exit(1)

# Paths to Reports files
reports_applib = '/u01/app/oracle/product/fmw14.1.2.0/reports/j2ee/oracle.reports.applib.jar'
reports_ear = '/u01/app/oracle/product/fmw14.1.2.0/reports/j2ee/reports.ear'

# Check if files exist
if not os.path.exists(reports_applib):
    print('ERROR: Reports AppLib not found at: ' + reports_applib)
    disconnect()
    sys.exit(1)

if not os.path.exists(reports_ear):
    print('ERROR: Reports EAR not found at: ' + reports_ear)
    disconnect()
    sys.exit(1)

print('Reports files found successfully')
print('')

# Use ServerRuntime tree to check deployments without edit session
try:
    print('Checking existing deployments...')
    serverRuntime()
    cd('AppRuntimeStateRuntime')
    cd('AppRuntimeStateRuntime')

    # Check current deployments
    domainRuntime()
    cd('DeployerRuntime')
    cd('DeployerRuntime')

    print('Switching to DomainRuntime for deployment...')
    domainRuntime()

except Exception as e:
    print('Note: ' + str(e))

# Now do the actual deployment
print('')
print('Starting deployment process...')
print('')

try:
    # Deploy the shared library
    print('1. Deploying oracle.reports.applib shared library...')
    progress = deploy(appName='oracle.reports.applib',
                     path=reports_applib,
                     targets='WLS_REPORTS',
                     libraryModule='true',
                     upload='false',
                     block='true',
                     timeout=120000)
    print('   AppLib deployed successfully')
    print('')

except Exception as e:
    error_msg = str(e)
    if 'already exists' in error_msg or 'deployment already' in error_msg.lower():
        print('   AppLib already deployed (OK)')
        print('')
    else:
        print('   Warning: AppLib deployment issue: ' + error_msg)
        print('   Continuing with Reports application deployment...')
        print('')

try:
    # Deploy the Reports application
    print('2. Deploying reports.ear application...')
    progress = deploy(appName='reports',
                     path=reports_ear,
                     targets='WLS_REPORTS',
                     upload='false',
                     block='true',
                     timeout=180000)
    print('   Reports application deployed successfully')
    print('')

except Exception as e:
    error_msg = str(e)
    if 'already exists' in error_msg or 'deployment already' in error_msg.lower():
        print('   Reports already deployed (OK)')
        print('')
    else:
        print('   ERROR: Reports deployment failed: ' + error_msg)
        print('')
        disconnect()
        sys.exit(1)

# Try to start the application
try:
    print('3. Starting Reports application...')
    startApplication('reports', 'WLS_REPORTS', block='true')
    print('   Reports application started successfully')
    print('')
except Exception as e:
    error_msg = str(e)
    if 'already' in error_msg.lower() or 'running' in error_msg.lower():
        print('   Reports already running (OK)')
        print('')
    else:
        print('   Warning: Could not start application: ' + error_msg)
        print('   Application may need manual start via WebLogic Console')
        print('')

# Disconnect
disconnect()

print('')
print('========================================')
print('Deployment Process Completed!')
print('========================================')
print('')
print('Next steps:')
print('1. Check deployment status in WebLogic Console: http://localhost:7001/console')
print('2. Test Reports Servlet: http://localhost:9002/reports/rwservlet?server=help')
print('3. Run your JSP report:')
print('   http://localhost:9002/reports/rwservlet?report=BATCH-TEMPORARY.jsp&userid=user/pass@db&desformat=pdf&destype=cache')
print('')
