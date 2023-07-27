#!/bin/bash

# Checking windscribe
if [ $(pgrep windscribe | wc -l) -eq 0 ]; then
    echo "Windscribe process not running" 2>/proc/1/fd/2
    
    #
    # We could try to restore this, but we don't know why this is not running. 
    # It may just end up in some infinite loop. Better to quit the container 
    # and have the restart configurations deal with this one as it sees fit.
    #
    if [ -f /var/run/init.pid ]; then
        kill -s SIGKILL $(cat /var/run/init.pid)
    fi
    
    exit 1
    
elif ! expect /opt/scripts/windscribe-health-check.expect >/proc/1/fd/1 2>/proc/1/fd/2 || ! ping -c 1 google.com >/dev/null 2>&1; then
    echo "Network is down, re-setting windscribe connection" 2>/proc/1/fd/2
    
    /opt/init/vpn-disconnect.sh >/proc/1/fd/1 2>/proc/1/fd/2
    if ! /opt/init/vpn-connect.sh >/proc/1/fd/1 2>/proc/1/fd/2; then
        exit 1
    fi
fi

# Check the app health
if [ -f /app/app-health-check.sh ]; then
    if ! bash /app/app-health-check.sh >/proc/1/fd/1 2>/proc/1/fd/2; then
        exit 1
    fi
fi

exit 0

