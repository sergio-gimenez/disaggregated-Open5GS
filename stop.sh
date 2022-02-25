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

# Kill qemu vms
kill_qemu() {
    PIDFILE=$1
    PID=$(cat $PIDFILE)
    if [ -n $PID ]; then
        kill $PID
        while [ -n "$(ps -p $PID -o comm=)" ]; do
            sleep 1
        done
    fi

    rm $PIDFILE

}
CUR_PATH=$(pwd)
kill_qemu "$CUR_PATH"/"$1".pid
