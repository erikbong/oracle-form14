#!/usr/bin/env python
"""
WLST Script to cancel any pending edit sessions
"""

print('Canceling any pending edit sessions...')

# Connect to AdminServer
connect('weblogic', 'Oracle123', 't3://localhost:7001')

# Try to get the configuration manager and cancel edit sessions
try:
    cmgr = getConfigManager()
    if cmgr.haveUnactivatedChanges():
        print('Found unactivated changes, canceling...')
        cmgr.cancelEdit()
        print('Edit session canceled')
    else:
        print('No pending edit sessions found')
except Exception as e:
    print('Error checking/canceling edit sessions: ' + str(e))

disconnect()
print('Done')
