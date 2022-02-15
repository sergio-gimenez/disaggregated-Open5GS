#!/bin/sh

ip tuntap add ogstun1 mode tun
ip addr add 10.45.0.1/16 dev ogstun1
ip link set ogstun1 up
exit 0
