#!/bin/bash

# Kill switch & IPCP
kill -9 $(pidof pidof l2-switch)
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

kill_qemu vm1.pid
kill_qemu vm2.pid
kill_qemu vm3.pid

sleep 2
echo
echo "Showing memory areas where netmap pipes are allocated:"
echo "(No memory areas should be allocated, so no text should be seen below)"

sudo vale-ctl
