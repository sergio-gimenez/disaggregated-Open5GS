#!/bin/bash

display_usage() {
    echo -e "\nUsage: $0 [vm1 vm2 vm3] \n"
}

# check whether user had supplied -h or --help . If yes display usage
if [[ ($# == "--help") || $# == "-h" ]]; then
    display_usage
    exit 0
fi

# if less than two arguments supplied, display usage
if [ $# -le 0 ]; then
    echo "This script must be run with at least one argument."
    display_usage
    exit 1
fi

# display usage if the script is not run as root user
if [[ "$EUID" -ne 0 ]]; then
    echo "This script must be run as root!"
    exit 1
fi

function remove_services() {
    OPEN5GS_SERVICES=$(systemctl list-unit-files | grep open5gs | awk '{print $1}')

    for SERVICE in $OPEN5GS_SERVICES; do
        systemctl stop $SERVICE
        systemctl disable $SERVICE
    done
}

function setup_vm() {
    remove_services

    if [ "$1" == "vm1" ]; then
        systemctl enable open5gs-nrfd
        systemctl start open5gs-nrfd
        sleep 5
        systemctl enable open5gs-mmed
        systemctl start open5gs-mmed
        systemctl enable open5gs-sgwcd
        systemctl start open5gs-sgwcd
        systemctl enable open5gs-smfd
        systemctl start open5gs-smfd
        systemctl enable open5gs-hssd
        systemctl start open5gs-hssd
        systemctl enable open5gs-pcrfd
        systemctl start open5gs-pcrfd
    fi
}

setup_vm $1
