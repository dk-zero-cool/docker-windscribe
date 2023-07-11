#!/bin/bash

# Verify the network is up

bash /opt/scripts/vpn-health-check.sh

if [ ! $? -eq 0 ]; then
    exit 1;
fi

# Check the app health
if [ -f /config/app-health-check.sh ]; then
    if ! bash /config/app-health-check.sh; then
        exit 1
    fi
    
elif [ -f /opt/scripts/app-health-check.sh ]; then
    if ! bash /opt/scripts/app-health-check.sh; then
        exit 1
    fi
fi

exit 0

