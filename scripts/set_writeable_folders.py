#!/usr/bin/env python
# WLST Script to configure Reports Server writeable folders via MBean

print('='*70)
print('Setting Reports Server Writeable Folders')
print('='*70)

# Connect to AdminServer
connect('weblogic', 'Oracle123', 't3://localhost:7001')

print('\nConnected to Admin Server')

# Try to find and configure the Reports Server MBean
try:
    print('\nAttempting to configure writeable folders...')

    # Method 1: Try through custom MBean tree
    try:
        custom()
        print('Navigating to Reports Server MBean...')

        # Try different possible paths
        paths_to_try = [
            '/oracle.reports.serverconfig/ReportsServer/rep_wls_reports_oracle-forms',
            '/oracle.reports.serverconfig/oracle.reports.server/rep_wls_reports_oracle-forms',
            '/ReportsServerComponent/rep_wls_reports_oracle-forms'
        ]

        for path in paths_to_try:
            try:
                print('  Trying path: ' + path)
                cd(path)
                print('  SUCCESS: Found MBean at: ' + path)

                # List available operations and attributes
                print('\nAvailable attributes:')
                ls()

                # Try to set writeable folders
                writeable_folders = '/u01/app/oracle/config/domains/forms_domain/reports/cache;/tmp;/u01/app/oracle/reports_source'

                # Try different attribute names
                attr_names = ['writeableFolders', 'WriteableFolders', 'writableFolders']

                for attr in attr_names:
                    try:
                        print('\n  Trying to set attribute: ' + attr)
                        set(attr, writeable_folders)
                        print('  SUCCESS: Set ' + attr + ' = ' + writeable_folders)
                        break
                    except:
                        print('  Attribute ' + attr + ' not found, trying next...')

                # Try to navigate to configuration sub-node
                try:
                    cd('Configuration/rwserver')
                    print('\n  Found Configuration/rwserver node')
                    ls()
                except:
                    pass

                break

            except Exception as e:
                print('  Path not found: ' + str(e))
                continue

        # Save changes
        save()
        activate()
        print('\nConfiguration saved!')

    except Exception as e:
        print('Method 1 failed: ' + str(e))

    # Method 2: Try through domainConfig tree
    try:
        print('\n\nTrying alternative method via domainConfig...')
        domainConfig()
        cd('/Servers/WLS_REPORTS')
        print('At WLS_REPORTS server')
        ls()

    except Exception as e:
        print('Method 2 failed: ' + str(e))

except Exception as e:
    print('\nERROR: ' + str(e))
    import traceback
    traceback.print_exc()

print('\n' + '='*70)
print('Script completed')
print('='*70)
print('\nNOTE: If writeableFolders could not be set via WLST,')
print('you must configure it through Enterprise Manager Console')
print('or manually edit the runtime MBean configuration.')
print('='*70)

disconnect()
