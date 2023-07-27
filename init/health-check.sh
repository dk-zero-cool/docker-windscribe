#!/bin/bash

# Checking windscribe
if [ $(pgrep windscribe | wc -l) -eq 0 ]; then
    echo "Windscribe process not running"
    exit 1
    
elif ! expect /opt/scripts/windscribe-health-check.expect || ! ping -c 1 google.com >/dev/null 2>&1; then
    echo "Network is down, re-setting windscribe connection"
    
    /opt/init/vpn-disconnect.sh
    if ! /opt/init/vpn-connect.sh; then
        exit 1
    fi
fi

# Check the app health
if [ -f /app/app-health-check.sh ]; then
    if ! bash /app/app-health-check.sh; then
        exit 1
    fi
fi

exit 0

