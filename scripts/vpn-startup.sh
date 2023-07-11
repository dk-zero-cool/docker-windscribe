#!/bin/bash

# Create a TUN device
mkdir -p /dev/net
mknod /dev/net/tun c 10 200
chmod 0666 /dev/net/tun

# Create docker user
usermod -u $PUID docker_user 2>/dev/null
groupmod -g $PGID docker_group 2>/dev/null
chown -R docker_user:docker_group /config

declare -i state=1
declare -a expects=(
    /opt/scripts/vpn-login.expect
    /opt/scripts/vpn-lanbypass.expect
    /opt/scripts/vpn-protocol.expect
    /opt/scripts/vpn-port.expect
    /opt/scripts/vpn-firewall.expect
    /opt/scripts/vpn-connect.expect
)

# Start the windscribe service
if service windscribe-cli start; then
    # Set up the windscribe DNS server
    echo "nameserver 10.255.255.1" >> /etc/resolv.conf
    
    while :; do
        for exp in ${expects[@]}; do
            if ! expect $exp; then
                break 2
            fi
        done
        
        # Wait for the connection to come up
        i="0"
        expect /opt/scripts/vpn-health-check.expect
        while [[ ! $? -eq 0 ]]; do
            sleep 2
            echo "Waiting for the VPN to connect... $i"
            i=$[$i+1]
            if [[ $i -eq "15" ]]; then
                break 2
            fi
            expect /opt/scripts/vpn-health-check.expect
        done
        
        if [ -f /config/iptables.rules ]; then
            echo "Restoring custom iptables rules"
            /sbin/iptables-restore /config/iptables.rules
        fi
        
        if [ -f /config/app-setup.sh ]; then
            echo "Running custom app setup"
            bash /config/app-setup.sh
            
        elif [ -f /opt/scripts/app-setup.sh ]; then
            echo "Running custom app setup"
            bash /opt/scripts/app-setup.sh
        fi
        
        echo "Windscribe is connected and running"
        state=0
        
        break
    done
fi

if [[ $state -eq 0 && -f /config/app-startup.sh ]]; then
    echo "Launching custom app run environment"
    su -w VPN_PORT -g docker_group - docker_user -c "bash /config/app-startup.sh"
    
elif [[ $state -eq 0 && -f /opt/scripts/app-setup.sh ]]; then
    echo "Launching custom app run environment"
    su -w VPN_PORT -g docker_group - docker_user -c "bash /opt/scripts/app-startup.sh"

else
    trap : TERM INT; sleep infinity & wait
fi

