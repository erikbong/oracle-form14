# WLST Script to create basic WebLogic domain
print('Starting WebLogic domain creation...')

# Read the base WebLogic template
readTemplate('/u01/app/oracle/product/fmw14.1.2.0/wlserver/common/templates/wls/wls.jar')

# Set admin credentials
print('Setting admin credentials...')
cd('/')
cd('Security/base_domain/User/weblogic')
cmo.setName('weblogic')
cmo.setPassword('Oracle123')

# Configure AdminServer
print('Configuring AdminServer...')
cd('/Server/AdminServer')
cmo.setName('AdminServer')
cmo.setListenAddress('')
cmo.setListenPort(7001)

# Create basic managed servers for Forms and Reports
print('Creating managed servers...')
cd('/')

# Create Forms server
print('Creating Forms Server (WLS_FORMS)...')
create('WLS_FORMS', 'Server')
cd('/Server/WLS_FORMS')
cmo.setListenAddress('')
cmo.setListenPort(9001)

# Create Reports server
print('Creating Reports Server (WLS_REPORTS)...')
cd('/')
create('WLS_REPORTS', 'Server')
cd('/Server/WLS_REPORTS')
cmo.setListenAddress('')
cmo.setListenPort(9002)

# Write domain and close
print('Writing domain to /u01/app/oracle/config/domains/forms_domain...')
writeDomain('/u01/app/oracle/config/domains/forms_domain')
closeTemplate()
print('Domain creation completed successfully!')
exit()