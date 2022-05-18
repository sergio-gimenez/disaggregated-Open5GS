#!/bin/bash

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

if checkdep make build-essential http://launchpad.net/build-essential; then
    echo "All needed dependencies properly installed. (${FOUND})"
else
    echo "installing missing deps:"
    sudo apt install build-essential -y
fi

git clone https://github.com/luigirizzo/netmap.git
cd netmap
./configure --no-drivers --enable-ptnetmap
make
sudo make install

sudo depmod -a
sudo modprobe netmap
