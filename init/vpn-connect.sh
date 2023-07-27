#!/bin/bash

# Create a TUN device
mkdir -p /dev/net 2>/dev/null
mknod /dev/net/tun c 10 200
chmod 0666 /dev/net/tun

# Declare the windscribe control files
declare -a expects=(
    /opt/init/windscribe-login.expect
    /opt/init/windscribe-lanbypass.expect
    /opt/init/windscribe-protocol.expect
    /opt/init/windscribe-port.expect
    /opt/init/windscribe-firewall.expect
    /opt/init/windscribe-connect.expect
)

# Start the windscribe service
if service windscribe-cli start; then
    for exp in ${expects[@]}; do
        if ! expect $exp; then
            exit 1
        fi
    done
    
    # Wait for the connection to come up
    ts=$(date +%s)
    while :; do
        td=$(( $(date +%s) - $ts ))
    
        echo "Waiting for the VPN to connect... $td seconds"
        
        if ! expect /opt/init/windscribe-health-check.expect; then
            if [ $td -ge 30 ]; then
                break 2
            fi
            
            exit 1
            
        else
            break
        fi
    done
    
    echo "Windscribe is connected and running"
    
    # Set up the windscribe DNS server
    cp /etc/resolv.conf /etc/resolv.conf.orig
    echo "nameserver 10.255.255.1" >> /etc/resolv.conf
    
    if [ -f /app/iptables.rules ]; then
        echo "Restoring custom iptables rules"
        /sbin/iptables-restore /app/iptables.rules
    fi
    
    exit 0
fi

exit 1

