#!/usr/bin/env python
"""
WLST Script to create Reports Server System Component
This creates the proper Reports Server instance for standalone web deployment
"""

import os
import socket

# Get hostname for instance names
hostname = socket.gethostname()

# Connect to AdminServer
print('Connecting to AdminServer...')
connect('weblogic', 'Oracle123', 't3://localhost:7001')

# Start editing
print('Starting edit session...')
edit()
startEdit()

# Get the machine reference (should already exist from domain creation)
print('Getting machine reference...')
cd('/')
machines = ls('/Machines', returnMap='true')
if machines and len(machines) > 0:
    # Convert ArrayList/dict to list and get first item
    machine_list = list(machines)
    machine_name = machine_list[0]
    print('Using existing machine: ' + machine_name)
else:
    # Create machine if it doesn't exist
    machine_name = 'AdminServerMachine'
    print('Creating machine: ' + machine_name)
    cd('/')
    create(machine_name, 'UnixMachine')
    cd('/Machines/' + machine_name + '/NodeManager/' + machine_name)
    set('ListenAddress', 'localhost')
    set('ListenPort', 5556)
    machine_name = 'AdminServerMachine'

# Create Reports Tools Instance
print('Creating Reports Tools Instance...')
try:
    createReportsToolsInstance(instanceName='reptools1', machine=machine_name)
    print('Reports Tools Instance created successfully')
except Exception as e:
    print('Reports Tools Instance creation failed or already exists: ' + str(e))

# Create Reports Server Instance
print('Creating Reports Server Instance...')
reports_instance_name = 'repsvr_' + hostname
try:
    createReportsServerInstance(instanceName=reports_instance_name, machine=machine_name)
    print('Reports Server Instance created: ' + reports_instance_name)
except Exception as e:
    print('Reports Server Instance creation failed or already exists: ' + str(e))

# Save and activate changes
print('Saving configuration...')
save()
activate(block='true')

# Disconnect
print('Disconnecting...')
disconnect()

print('Reports Server configuration completed!')
print('Instance name: ' + reports_instance_name)
print('')
print('Next steps:')
print('1. Start WLS_REPORTS: $DOMAIN_HOME/bin/startManagedWebLogic.sh WLS_REPORTS')
print('2. Start Reports Server: opmnctl startproc ias-component=' + reports_instance_name)
print('3. Access reports at: http://localhost:9002/reports/rwservlet')
