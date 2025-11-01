#!/usr/bin/env python
"""
Deploy Reports Application to WLS_REPORTS (Online WLST)
This deploys the Reports servlet application to the running WLS_REPORTS server
"""

print('Deploying Reports Application to WLS_REPORTS...')

# Connect to AdminServer
connect('weblogic', 'Oracle123', 't3://localhost:7001')

# Check if reports application already deployed
print('Checking existing deployments...')
cd('/')
deployments = cmo.getAppDeployments()
reports_deployed = False
for app in deployments:
    if 'reports' in str(app.getName()).lower():
        print('Reports application already deployed: ' + str(app.getName()))
        reports_deployed = True
        break

if not reports_deployed:
    print('Reports application not found - need to deploy manually')
    print('')
    print('Looking for Reports application archive...')

    import os
    # Common locations for Reports application
    search_paths = [
        '/u01/app/oracle/product/fmw14.1.2.0/reports/jlib/reports.ear',
        '/u01/app/oracle/product/fmw14.1.2.0/reports/jlib/rwservlet.war',
        '/u01/app/oracle/product/fmw14.1.2.0/reports/ear/reports.ear',
        '/u01/app/oracle/product/fmw14.1.2.0/oracle_common/modules/oracle.reports.jar'
    ]

    reports_app = None
    for path in search_paths:
        if os.path.exists(path):
            reports_app = path
            print('Found Reports application at: ' + path)
            break

    if reports_app:
        try:
            print('Deploying Reports application...')
            deploy('reports', reports_app, targets='WLS_REPORTS')
            print('Reports application deployed successfully')
        except Exception as e:
            print('Deployment failed: ' + str(e))
    else:
        print('ERROR: No Reports application archive found')
        print('Reports must be deployed manually via WebLogic Console')

# Show server groups for WLS_REPORTS
print('')
print('Checking WLS_REPORTS configuration...')
cd('/Servers/WLS_REPORTS')
print('WLS_REPORTS listen port: ' + str(cmo.getListenPort()))

# Disconnect
disconnect()
print('')
print('Done. Check http://localhost:9002/reports/rwservlet')
exit()
