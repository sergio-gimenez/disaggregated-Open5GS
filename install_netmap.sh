#!/bin/bash

git clone https://github.com/luigirizzo/netmap.git
$(pwd)/netmap/configure --no-drivers --enable-ptnet
$(pwd)/netmap/make
sudo $(pwd)/netmap/make install

sudo depmod -a
sudo modprobe netmap
