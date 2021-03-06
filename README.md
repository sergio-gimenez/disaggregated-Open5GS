# Disaggregated Open5Gs in KVM guests

This is a deployment of an [Open5Gs](https://open5gs.org/) in separated KVM guests. This deployment is based on [Overview of Open5GS CUPS-enabled EPC Simulation Mobile Network](https://github.com/s5uishida/open5gs_epc_oai_sample_config). Check it for complete details about the deployment.

This document is detailed the networking and the configuration of the KVM guests in order to be able to use [netmap](https://github.com/luigirizzo/netmap), as well of the automation of the deployment via bash scripts. 

## Dependencies

The KVM guests will be deployed via a QEMU-KVM netmap-enabled fork. To install it:

Build and install qemu with netmap support on the host machine.

```source
git clone https://github.com/netmap-unipi/qemu
cd qemu
./configure --target-list=x86_64-softmmu --enable-kvm --disable-werror --enable-netmap 
make
sudo make install
```

## Disaggregated Open5Gs in KVM guests on the same physical host

![open5gs_deployment.drawio.png](open5gs_deployment.drawio.png)

There are two available types of networking: `normal` and `netmap`. The `normal` deployment follows a typical VM networking configuration by running a `virtio` driver as virtual NIC, a `tap` device as networking backend and finally a `linux-bridge` device as networking bridge. On the other hand, the `netmap` deployment uses the `ptnet` driver as virtual NIC, a `netmap-pipe` device as networking backend and finally a layer 2 switch implemented from scratch as networking bridge.

### TL;DR

```source
# Install netmap first if you haven't
git clone https://github.com/luigirizzo/netmap.git
cd netmap
./configure --no-drivers --enable-ptnetmap
make
sudo make install
sudo depmod -a
sudo modprobe netmap
cd ..

# Do same procedure for every VM (vm1, vm2, vm3)
(host) $ sudo ./build_vms.sh vmX [normal|netmap]
(host) $ ssh ubuntu@localhost -p 202X
(guest) $ git clone https://github.com/sergio-gimenez/disaggregated-Open5GS.git
(guest) $ cd disaggregated-Open5GS
(guest) $ ./setup_vms.sh  vmX setup-net

# Start the desired Open5GS services in each guest (vm1, vm2, vm3)
(guest) $ ./start_vms.sh  vmX start

# Enable networking by running a bridge/netmap-l2-switch in the host

# normal networking:
(host) $ sudo setup_nost_net.sh

#netmap networking:
(host) $ sudo l2-switch -i vale1:01}1 -i vale1:02}1 -i vale1:03}1
# Switch needs to be compiled from source in from the RINA-OpenVerso repo
```

### Step by step deployment

Let's start first building the VMs. To do so, run the `build_vms.sh` script as root:

```source
sudo ./build_vms.sh vmX [normal|netmap]
```

Write either `normal` or `netmap` as the second argument for "normal" networking using linux bridges or for a netmap-based networking respectively.

This will install the needed dependencies as well as the ubuntu cloud base image to build the VM from a pre-created image. If everything is ok, the script will create the VMs and start them in a new window. The credentials of the VM can be specified in the `user_data.yaml` file.

Now, ssh into the VM. In order to do so, run the following command:

```source
ssh ubuntu@localhost -p 202X
```

Where `X` is the VM number. For example, if we built the `vm1`, then the ssh query to access it will be `ssh ubuntu@localhost -p 2021`. Note also that `ubuntu` is the default user name for ubuntu cloud-images.

Once inside the VM, first of all clone the repo:

```source
ubuntu@ubuntu:~$ git clone https://github.com/sergio-gimenez/disaggregated-Open5GS.git
```

Then, we have to first install netmap (only if we want to use the netmap networking version). To install netmap, run the following commands:

```source
sudo apt install build-essential -y # Install make and the C compiler
git clone https://github.com/luigirizzo/netmap.git
cd netmap
./configure --no-drivers --enable-ptnetmap
make
sudo make install
sudo depmod -a
sudo modprobe netmap
sudo apt install net-tools # Just to have ifconfig command
sudo ifconfig ens4 up
```

To double check netmap-passthrough is working in the VM, you can do `ifconfig ens4` and the output:

```source
ubuntu@ubuntu:~/netmap$ ifconfig ens4
ens4: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet6 fe80::20a:aff:fe0a:101  prefixlen 64  scopeid 0x20<link>
        ether 00:0a:0a:0a:01:01  txqueuelen 1000  (Ethernet)
        RX packets 0  bytes 0 (0.0 B)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 9  bytes 726 (726.0 B)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
```

And see that the MAC address is the one we specified in the script (`00:0a:0a:0a:01:01`).

Also, we can see that the `ptnet` driver is properly running by using the `ethtool` utility:

```source

```ubuntu@ubuntu:~/netmap$ ethtool -i ens4
driver: ptnetmap-guest-drivers
...
```
Or run the `install_netmap` script **without being root**.
> Seems that `install_netmap.sh` does not work for some reason

```source
./install_netmap.sh
```

This will compile and insert the netmap kernel module into the VM in order to enable netmap-passthrough (i.e., make the guest-host communication using netmap work).

Once netmap is installed, we can setup the networking. To do so, run the following script inside the VM:

```source
(VM) $ sudo ./setup_vms.sh [vm1 vm2 vm3] [setup-net start]
```

* The `setup-net` option will start the needed networking (i.e., creating `tun` interface with appopiate names and addresses, etc.). (More details on what's going on under the hood [here](https://github.com/s5uishida/open5gs_epc_oai_sample_config#changes-in-configuration-files-of-open5gs-epc-and-oai-ue--ran))

* The `start` option will start the needed Open5Gs services.

Finally, we need to enable the L2 network in the host.

* For the `normal` networking, you just have to run the following script:

    ```source
    sudo ./setup_host_net.sh
    ```

* For the `netmap` networking, the `l2-switch` must be compiled from source and then executed.

## Disaggregated Open5Gs in KVM guests on different physical hosts

![physical_testbed_open5gs_deployment.drawio.png](physical_testbed_open5gs_deployment.drawio.png)

References used and nice to check:

* [Open5GS Quickstart](https://open5gs.org/open5gs/docs/guide/01-quickstart/)
* [Building Open5GS from sources](https://open5gs.org/open5gs/docs/guide/02-building-open5gs-from-sources/)
* [Boot Ubuntu providing it network config in NoCloud Datasource](https://gist.github.com/smoser/635897f845f7cb56c0a7ac3018a4f476)
* [Open5GS EPC & OpenAirInterface UE / RAN Sample Configuration](https://github.com/s5uishida/open5gs_epc_oai_sample_config)