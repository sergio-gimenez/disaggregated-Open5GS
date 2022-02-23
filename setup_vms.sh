#!/bin/bash

display_usage() {
    echo -e "\nUsage: $0 [vm1 vm2 vm3] [setup-net start]\n"
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

function display_services() {
    echo "Active services:"
    echo "$(systemctl list-units | grep open5gs)"
}

function remove_services() {
    OPEN5GS_SERVICES=$(systemctl list-unit-files | grep open5gs | awk '{print $1}')

    for SERVICE in $OPEN5GS_SERVICES; do
        systemctl stop $SERVICE
        systemctl disable $SERVICE
    done
}

function setup_networking() {
    O5GS_CNF_PATH=/etc/open5gs
    PWD=$(pwd)

    if [ "$1" == "vm1" ]; then
        rm $O5GS_CNF_PATH/mme.yaml
        cp $PWD/net_conf/mme.yaml $O5GS_CNF_PATH/

        rm $O5GS_CNF_PATH/sgwc.yaml
        cp $PWD/net_conf/sgwc.yaml $O5GS_CNF_PATH/

        rm $O5GS_CNF_PATH/smf.yaml
        cp $PWD/net_conf/smf.yaml $O5GS_CNF_PATH/

        set -x
        ip addr add 192.168.0.111/24 dev ens4
        ip link set ens4 up
        set +x
    fi

    if [ "$1" == "vm2" ]; then
        mv $PWD/net_conf/vm2_sgwu.yaml net_conf/sgwu.yaml
        rm $O5GS_CNF_PATH/sgwu.yaml
        cp $PWD/net_conf/sgwu.yaml $O5GS_CNF_PATH/

        mv $PWD/net_conf/vm2_upf.yaml net_conf/upf.yaml
        rm $O5GS_CNF_PATH/upf.yaml
        cp $PWD/net_conf/upf.yaml $O5GS_CNF_PATH/

        set -x
        # Add the IP address and enable the CP interface
        ip addr add 192.168.0.112/24 dev ens4
        ip link set ens4 up

        # Enable IP forwarding
        sed -i 's/net.ipv4.ip_forward=0/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
        sysctl -p

        # Create the tun interfaces to enable p2p for GTP
        ip tuntap add name ogstun mode tun
        ip addr add 10.45.0.1/16 dev ogstun
        ip link set ogstun up

        iptables -t nat -A POSTROUTING -s 10.45.0.0/16 ! -o ogstun -j MASQUERADE

        ip tuntap add name ogstun2 mode tun
        ip addr add 10.46.0.1/16 dev ogstun2
        ip link set ogstun2 up

        iptables -t nat -A POSTROUTING -s 10.46.0.0/16 ! -o ogstun2 -j MASQUERADE
        set +x
    fi

    if [ "$1" == "vm3" ]; then
        mv $PWD/net_conf/vm3_sgwu.yaml net_conf/sgwu.yaml
        rm $O5GS_CNF_PATH/sgwu.yaml
        cp $PWD/net_conf/sgwu.yaml $O5GS_CNF_PATH/

        mv $PWD/net_conf/vm3_upf.yaml net_conf/upf.yaml
        rm $O5GS_CNF_PATH/upf.yaml
        cp $PWD/net_conf/upf.yaml $O5GS_CNF_PATH/

        set -x
        # Enable the CP interface
        ip addr add 192.168.0.113/24 dev ens4
        ip link set ens4 up

        # Create the tun interfaces to enable p2p for GTP
        ip tuntap add name ogstun3 mode tun
        ip addr add 10.47.0.1/16 dev ogstun3
        ip link set ogstun3 up

        # Enable IP forwarding and NAPT.
        # This seems like is enough to enable that the private IP network can talk with a destination public IP network.
        sed -i 's/net.ipv4.ip_forward=0/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
        sysctl -p
        iptables -t nat -A POSTROUTING -s 10.47.0.0/16 ! -o ogstun3 -j MASQUERADE
        set +x
    fi
}

function setup_services() {
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

    if [ "$1" == "vm2" ] || [ "$1" == "vm3" ]; then
        systemctl enable open5gs-sgwud
        systemctl start open5gs-sgwud
        systemctl enable open5gs-upfd
        systemctl start open5gs-upfd
    fi

    display_services
}

# Install open5gs from apt repository (if not installed)
if [ "$(dpkg -l | awk '/open5gs/ {print }' | wc -l)" -lt 1 ]; then
    echo " Open5GS not installed, installing... "
    sudo apt update
    sudo add-apt-repository ppa:open5gs/latest -y
    sudo apt update
    sudo apt install open5gs -y
fi

if [ "$2" == "setup-net" ]; then
    setup_networking $1
    exit
fi

if [ "$2" == "start" ]; then
    remove_services
    sleep 2
    setup_services $1
    exit
fi

echo "Please specify a valid argument."
display_usage
