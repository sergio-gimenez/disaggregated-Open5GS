#!/bin/bash

display_usage() {
    echo -e "\nUsage: $0 [vm1 vm2 vm3] [normal netmap]\n"
}

# check whether user had supplied -h or --help . If yes display usage
if [[ ($# == "--help") || $# == "-h" ]]; then
    display_usage
    exit 0
fi

# display usage if the script is not run as root user
if [[ "$EUID" -ne 0 ]]; then
    echo "This script must be run as root!"
    exit 1
fi

# if less than two arguments supplied, display usage
if [ $# -le 1 ]; then
    echo "This script must be run with at least two arguments."
    display_usage
    exit 1
fi

CUR_PATH=$(pwd)
VM_NAME="$1"
NUM="${VM_NAME: -1}"

if [ "$2" == "normal" ]; then
    NET_FRONTEND="virtio-net-pci"
    NET_BACKEND="tap"
    BACK_IFNAME=""$VM_NAME".cp"
    IFUP_SCRIPTS=",script=no,downscript=no"

elif [ "$2" == "netmap" ]; then
    # Make sure netmap module is loaded
    if ! lsmod | grep "netmap" &>/dev/null; then
        echo "netmap module is not loaded. Loading."
        modprobe netmap
    fi
    NET_FRONTEND="ptnet-pci"
    NET_BACKEND="netmap"
    BACK_IFNAME="vale2:1}2"
    IFUP_SCRIPTS=",passthrough=on"

else

    echo "Unknown network type"
    display_usage
    exit 1
fi

# Boot the vm
sudo qemu-system-x86_64 \
    "$CUR_PATH"/"$VM_NAME".img \
    -m 2G --enable-kvm -pidfile $VM_NAME.pid \
    -serial file:"$VM_NAME".log \
    -device e1000,netdev=mgmt,mac=00:AA:BB:CC:01:99 -netdev user,id=mgmt,hostfwd=tcp::202"$NUM"-:22 \
    -device "$NET_FRONTEND",netdev=data1,mac=00:0a:0a:0a:0"$NUM":01 -netdev $NET_BACKEND,ifname="$BACK_IFNAME",id=data1"$IFUP_SCRIPTS" &
