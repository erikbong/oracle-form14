#!/usr/bin/env python
"""
Check deployment status
"""

connect('weblogic', 'Oracle123', 't3://localhost:7001')

print('========================================')
print('Checking Deployments on WLS_REPORTS')
print('========================================')
print('')

# Check libraries
print('Libraries:')
domainRuntime()
cd('AppRuntimeStateRuntime/AppRuntimeStateRuntime')
libraries = cmo.getLibraryRuntimes()
for lib in libraries:
    name = lib.getName()
    targets = lib.getDeploymentState()
    print('  - ' + name + ' : ' + str(targets))

print('')
print('Applications:')
apps = cmo.getApplicationRuntimes()
for app in apps:
    name = app.getName()
    state = app.getDeploymentState()
    print('  - ' + name + ' : ' + str(state))

disconnect()
print('')
