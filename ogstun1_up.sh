#!/bin/sh

ip tuntap add ogstun1 mode tun
ip addr add 10.45.0.1/16 dev ogstun1
ip link set ogstun1 up
exit 0


# set -x

# if [ -n "$1" ];then
#     ip tuntap add $1 mode tun
#     ip addr add 10.45.0.1/16 dev $1
#     ip link set $1 up
#     exit 0
# else
#     echo "Error: no interface specified"
#     exit 1
# fi
