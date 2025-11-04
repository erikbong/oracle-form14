#!/bin/bash
set -e

echo "Starting Oracle Forms & Reports 14c container..."

# Start VNC as oracle user
echo "Starting VNC server..."
su - oracle -c "vncserver :1 -geometry 1280x1024 -depth 24 -localhost no"

# Auto-start services if enabled
if [ "$AUTO_START_SERVICES" = "true" ] && [ -f /u01/app/oracle/middleware/startAllServices.sh ]; then
    echo "Auto-starting Oracle services in 10 seconds..."
    sleep 10
    
    # Start services as oracle user in background
    su - oracle -c "/u01/app/oracle/middleware/startAllServices.sh" > /u01/app/oracle/middleware/logs/autostart.log 2>&1 &
    
    echo "Services startup initiated. Waiting for logs..."
    sleep 5
    
    # Tail logs to keep container running
    tail -f /u01/app/oracle/middleware/logs/autostart.log 2>/dev/null || \
    tail -f /u01/app/oracle/middleware/logs/adminserver.log 2>/dev/null || \
    tail -f /dev/null
else
    echo "Auto-start disabled or startup script not found."
    tail -f /dev/null
fi
