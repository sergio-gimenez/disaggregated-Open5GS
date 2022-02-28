#!/bin/bash

# display usage if the script is not run as root user
if [[ "$EUID" -ne 0 ]]; then
    echo "This script must be run as root!"
    exit 1
fi

if [ $# -le 0 ]; then
    echo "This script must be run with at least one argument."
    exit 1
fi

set +x

if [ "$1" == "up" ]; then

    if [ "$(dpkg -l | awk '/bridge-utils/ {print }' | wc -l)" -lt 1 ]; then
        apt install bridge-utils
    fi

    # Control Plane Bridge
    sudo brctl addbr ogsbr
    sudo ip link set ogsbr up

    sudo ip link set vm1.cp up
    sudo brctl addif ogsbr vm1.cp

    sudo ip link set vm2.cp up
    sudo brctl addif ogsbr vm2.cp

    sudo ip link set vm3.cp up
    sudo brctl addif ogsbr vm3.cp

    brctl show
fi

if [ "$1" == "down" ]; then
    sudo ip link set ogsbr down
    sudo brctl delbr ogsbr
fi
