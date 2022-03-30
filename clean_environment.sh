#!/bin/bash

# Kill switch & IPCP
echo "Killing L2-SW instance(s)"
kill -9 $(pidof pidof l2-switch)

echo "Killing IPCP instance"
kill -9 $(pidof pidof ipcp)

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

files=(
    "vm1.pid"
    "vm2.pid"
    "vm3.pid"
)
for file in "${files[@]}"; do
    if [ -f $file ]; then
        kill_qemu $file
        echo "Killed $file"
    fi
done

sleep 2
echo
echo "Showing memory areas where netmap pipes are allocated:"
echo "(No memory areas should be allocated, so no text should be seen below)"

sudo vale-ctl
