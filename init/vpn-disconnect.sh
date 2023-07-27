#!/bin/bash

# Stopping the windscribe service
if ! expect /opt/init/windscribe-disconnect; then
    # Failed to disconnect. 
    # Manual cleanup

    service windscribe-cli stop
    
    # Reset the TUN interface
    inet=$(ip -f inet addr show tun0 | awk '/inet / {print $2}')
    if [ -n "$inet" ]; then
        ip address del $inet dev tun0
    fi
    
    # Cleanup routes
    while read line; do
        ip r del $line
    
    done < <(ip r | grep tun0)
    
else
    service windscribe-cli stop
fi

# Remove the TUN device
rm /dev/net/tun

# Reset iptables
iptables -F
iptables -X

# Restore DNS
cat /etc/resolv.conf.orig > /etc/resolv.conf
rm /etc/resolv.conf.orig

echo "Windscribe is stopped and disconnected"

