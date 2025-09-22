# WLST Script to create domain
readTemplate('/u01/app/oracle/product/fmw14.1.2.0/wlserver/common/templates/wls/wls.jar')

# Set admin credentials
cd('/')
cd('Security/base_domain/User/weblogic')
cmo.setName('weblogic')
cmo.setPassword('Oracle123')

# Configure AdminServer
cd('/Server/AdminServer')
cmo.setName('AdminServer')
cmo.setListenAddress('')
cmo.setListenPort(7001)

# Navigate to root to create managed servers
cd('/')

# Create forms_server1
create('forms_server1', 'Server')
cd('/Server/forms_server1')
cmo.setListenAddress('')
cmo.setListenPort(9001)

# Create reports_server1
cd('/')
create('reports_server1', 'Server')
cd('/Server/reports_server1')
cmo.setListenAddress('')
cmo.setListenPort(9002)

# Write domain and close
writeDomain('/u01/app/oracle/config/domains/forms_domain')
closeTemplate()
exit()