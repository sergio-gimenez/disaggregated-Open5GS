# Instructions

Build and install qemu with nmap support on the host machine.

```source
git clone https://github.com/netmap-unipi/qemu
cd qemu
./configure --target-list=x86_64-softmmu --enable-kvm --disable-werror --enable-netmap 
make
sudo make install
```

Get base image:

```source
wget https://cloud-images.ubuntu.com/releases/focal/release/ubuntu-20.04-server-cloudimg-amd64.img
```

Create an overlay image:

```source
qemu-img create -f qcow2 -b ubuntu-20.04-server-cloudimg-amd64.img clean_open5gs.img
```

Resize image (20 GB minimum recommended):

```source
qemu-img resize clean_open5gs.img +22G
```

Build a cloud init image from a conf file:

```source
cloud-localds open5gs_init.img user_data.yaml
```

Instantiate the image:

```source
sudo qemu-system-x86_64 \
-hda ~/i2cat/disaggregated-Open5GS/clean_open5gs.img \
-hdb ~/i2cat/disaggregated-Open5GS/open5gs_init.img \
-m 2G --nographic --enable-kvm \
-serial file:endpoint1.log \
-device e1000,netdev=mgmt,mac=00:AA:BB:CC:01:99 -netdev user,id=mgmt,hostfwd=tcp::20021-:22
```

In order to install Open5GS on the image, you need to run the following commands:

Install mongodb:

```source
sudo apt update
sudo apt install mongodb
sudo systemctl start mongodb
sudo systemctl enable mongodb
```

Create the TUN device with the interface name ogstun (not persistent after rebooting):  

```source
sudo ip tuntap add name ogstun mode tun
sudo ip addr add 10.45.0.1/16 dev ogstun
sudo ip addr add 2001:db8:cafe::1/48 dev ogstun
sudo ip link set ogstun up
```

Now install Open5GS using apt (for Ubuntu systems):

```source
sudo apt update
sudo apt install software-properties-common
sudo add-apt-repository ppa:open5gs/latest
sudo apt update
sudo apt install open5gs
```

Now, we create the other VMs based on the image we just set up:

```source
cp clean_open5gs.img vm1.img
cp clean_open5gs.img vm2.img
cp clean_open5gs.img vm3.img
```

Now we can instantiate the VMs to configure them:

Caveats:

* Minimum of 1GB RAM is recommended.
* For some reason QEMU forces me to use the same MAC address in the management interface of all the VMs.

```source
sudo qemu-system-x86_64 \
~/i2cat/disaggregated-Open5GS/vm1.img \
-m 2G --nographic --enable-kvm -cpu host \
-serial file:vm1.log \
-device e1000,netdev=mgmt,mac=00:AA:BB:CC:01:99 -netdev user,id=mgmt,hostfwd=tcp::20021-:22
```

```source
sudo qemu-system-x86_64 \
-hda ~/i2cat/disaggregated-Open5GS/vm1.img \
-m 2G --nographic --enable-kvm -cpu host \
-serial file:vm1.log \
-device e1000,netdev=mgmt,mac=00:AA:BB:CC:01:99 -netdev user,id=mgmt,hostfwd=tcp::2021-:22
```

```source
sudo qemu-system-x86_64 \
~/i2cat/disaggregated-Open5GS/vm2.img \
-m 2G --nographic --enable-kvm -cpu host \
-serial file:vm2.log \
-device e1000,netdev=mgmt,mac=00:AA:BB:CC:01:99 -netdev user,id=mgmt,hostfwd=tcp::2022-:22
```

```source
sudo qemu-system-x86_64 \
~/i2cat/disaggregated-Open5GS/vm3.img \
-m 2G --nographic --enable-kvm -cpu host \
-serial file:vm3.log \
-device e1000,netdev=mgmt,mac=00:AA:BB:CC:01:99 -netdev user,id=mgmt,hostfwd=tcp::2023-:22
```

To connect via ssh:

```source
ssh ubuntu@localhost -p 2022
```

References used and nice to check:

* [Open5GS Quickstart](https://open5gs.org/open5gs/docs/guide/01-quickstart/)
* [Building Open5GS from sources](https://open5gs.org/open5gs/docs/guide/02-building-open5gs-from-sources/)
* [Boot Ubuntu providing it network config in NoCloud Datasource](https://gist.github.com/smoser/635897f845f7cb56c0a7ac3018a4f476)
* [Open5GS EPC & OpenAirInterface UE / RAN Sample Configuration](https://github.com/s5uishida/open5gs_epc_oai_sample_config)