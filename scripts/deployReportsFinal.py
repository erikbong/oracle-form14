#!/usr/bin/env python
"""
Final Reports deployment script - simplified
"""

print('Deploying Reports Application...')
print('')

# Connect
connect('weblogic', 'Oracle123', 't3://localhost:7001')

applib_path = '/u01/app/oracle/product/fmw14.1.2.0/reports/j2ee/oracle.reports.applib.jar'
reports_path = '/u01/app/oracle/product/fmw14.1.2.0/reports/j2ee/reports.ear'

print('Step 1: Deploying oracle.reports.applib library...')
try:
    progress = deploy(
        appName='oracle.reports.applib',
        path=applib_path,
        targets='WLS_REPORTS',
        libraryModule='true',
        block='false'
    )
    print('AppLib deployment initiated')
except Exception as e:
    if 'already' in str(e).lower():
        print('AppLib already deployed (OK)')
    else:
        print('AppLib deployment error: ' + str(e))

print('')
print('Step 2: Deploying reports.ear application...')
try:
    progress = deploy(
        appName='reports',
        path=reports_path,
        targets='WLS_REPORTS',
        block='false'
    )
    print('Reports deployment initiated')
except Exception as e:
    if 'already' in str(e).lower():
        print('Reports already deployed (OK)')
    else:
        print('Reports deployment error: ' + str(e))

print('')
print('Step 3: Starting reports application...')
try:
    startApplication('reports', 'WLS_REPORTS')
    print('Reports application started')
except Exception as e:
    if 'already' in str(e).lower() or 'running' in str(e).lower():
        print('Reports already running (OK)')
    else:
        print('Start error: ' + str(e))

disconnect()

print('')
print('========================================')
print('Deployment Complete!')
print('========================================')
print('Test URL: http://localhost:9002/reports/rwservlet?server=help')
print('')
