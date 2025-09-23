# WLST Script to enable Hosted WebLogic Remote Console
print('Enabling Hosted WebLogic Remote Console...')

# Connect to the running AdminServer
connect('weblogic', 'Oracle123', 't3://localhost:7001')

# Enable the hosted console
edit()
startEdit()

# Navigate to the domain and enable the hosted console
cd('/')
cd('RestfulManagementServices')

# Create RestfulManagementServices if it doesn't exist
try:
    cd('RestfulManagementServices')
    print('RestfulManagementServices already exists')
except:
    print('Creating RestfulManagementServices...')
    create('RestfulManagementServices', 'RestfulManagementServices')
    cd('RestfulManagementServices')

# Configure the hosted console
cmo.setEnabled(true)

# Save and activate changes
save()
activate()

print('Hosted WebLogic Remote Console enabled successfully!')
print('Access it at: http://localhost:7001/weblogic/remote-console/')

# Exit
exit()