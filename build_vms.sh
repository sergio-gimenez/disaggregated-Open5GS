#!/bin/bash

display_usage() {
    echo -e "\nUsage: $0 [vm1 vm2 vm3] \n"
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

# if less than one arguments supplied, display usage
if [ $# -le 0 ]; then
    echo "This script must be run with at least one argument."
    display_usage
    exit 1
fi

CLOUD_BASE_IMG="ubuntu-20.04-server-cloudimg-amd64.img"
CUR_PATH=$(pwd)
MISSING=""
FOUND=""

checkdep() {
    local exe="$1" package="$2" upstream="$3"
    if command -v "$1" >/dev/null 2>&1; then
        FOUND="${FOUND:+${FOUND} }$exe"
        return "0"
    fi
    MISSING=${MISSING:+${MISSING}$package}
    echo "missing $exe."
    echo "  It can be installed in package: $package"
    [ -n "$upstream" ] &&
        echo "  Upstream project url: $upstream"
    return 1
}

checkdep cloud-localds cloud-image-utils http://launchpad.net/cloud-utils
# checkdep genisoimage genisoimage
checkdep qemu-img qemu-utils http://qemu.org/
checkdep qemu-system-x86_64 qemu-system-x86 http://qemu.org/
checkdep wget wget

if [ -n "$MISSING" ]; then
    echo
    [ -n "${FOUND}" ] && echo "found: ${FOUND}"
    echo "install missing deps with:"
    echo "  apt-get update && apt-get install ${MISSING}"
else
    echo "All needed dependencies properly installed. (${FOUND})"
fi

# Create an overlay image
qemu-img create -f qcow2 -b "$CLOUD_BASE_IMG" "$1".img

qemu-img resize "$1".img +22G

# Build seed image with the user data and the networking config
# TODO This net conf is not working
# cloud-localds -v --network-config="$CUR_PATH"/net_conf_vm2.yaml \
#     "$CUR_PATH"/seed_"$1".img "$CUR_PATH"/user-data.yaml
cloud-localds "$CUR_PATH"/seed_"$1".img "$CUR_PATH"/user-data.yaml

# Boot the VM
if [ "$1" == "vm2" ]; then
    sudo qemu-system-x86_64 \
        -hda "$CUR_PATH"/"$1".img \
        -hdb "$CUR_PATH"/seed_"$1".img \
        -m 2G --enable-kvm \
        -serial file:"$1".log \
        -device e1000,netdev=mgmt,mac=00:AA:BB:CC:01:99 -netdev user,id=mgmt,hostfwd=tcp::2022-:22 \
        -device virtio-net-pci,netdev=data1,mac=00:0a:0a:0a:02:01 -netdev tap,ifname=d.01,id=data1,script=no,downscript=no \
        -device virtio-net-pci,netdev=data2,mac=00:0a:0a:0a:02:02 -netdev tap,ifname=d.02,id=data2,script=no,downscript=no
fi
