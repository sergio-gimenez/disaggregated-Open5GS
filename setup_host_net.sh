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
    sudo brctl addbr cpbr
    sudo ip link set cpbr up

    sudo ip link set vm1.cp up
    sudo brctl addif cpbr vm1.cp

    sudo ip link set vm2.cp up
    sudo brctl addif cpbr vm2.cp

    sudo ip link set vm3.cp up
    sudo brctl addif cpbr vm3.cp

    # User Plane Bridge
    sudo brctl addbr upbr
    sudo ip link set upbr up

    sudo ip link set vm2.up up
    sudo brctl addif upbr vm2.up

    sudo ip link set vm2.up1 up
    sudo brctl addif upbr vm2.up1

    sudo ip link set vm3.up up
    sudo brctl addif upbr vm3.up

    brctl show
fi

if [ "$1" == "down" ]; then
    # sudo ip link set vm1.cp down
    # sudo brctl delif cpbr vm1.cp

    # sudo ip link set vm2.cp down
    # sudo brctl delif cpbr vm2.cp

    # sudo ip link set vm3.cp down
    # sudo brctl delif cpbr vm3.cp

    sudo ip link set cpbr down
    sudo brctl delbr cpbr

    sudo ip link set upbr down
    sudo brctl delbr upbr
fi
