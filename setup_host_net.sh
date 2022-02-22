#!/bin/bash

# display usage if the script is not run as root user
if [[ "$EUID" -ne 0 ]]; then
    echo "This script must be run as root!"
    exit 1
fi

if [ "$(dpkg -l | awk '/bridge-utils/ {print }' | wc -l)" -lt 1 ]; then
    apt install bridge-utils
fi

sudo brctl addbr cpbr
sudo ip link set cpbr up

sudo ip link set vm1.cp up
sudo brctl addif cpbr vm1.cp

sudo ip link set vm2.cp up
sudo brctl addif cpbr vm2.cp

sudo ip link set vm3.cp up
sudo brctl addif cpbr vm3.cp


