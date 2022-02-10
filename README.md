# Instructions

Get base image:

```source
wget https://cloud-images.ubuntu.com/releases/focal/release/ubuntu-20.04-server-cloudimg-amd64.img
```

Create an overlay image:

```source
qemu-img create -f qcow2 -b ubuntu-20.04-server-cloudimg-amd64.img clean_open5gs.img
```

```source
qemu-img resize clean_open5gs.img +22G
```

```source
cloud-localds open5gs_init.img user_data.yaml
```

```source
sudo qemu-system-x86_64 \
-hda ~/i2cat/disaggregated-Open5GS/clean_open5gs.img \
-hdb ~/i2cat/disaggregated-Open5GS/open5gs_init.img \
-m 2G --nographic --enable-kvm \
-serial file:endpoint1.log \
-device e1000,netdev=mgmt,mac=00:AA:BB:CC:01:99 -netdev user,id=mgmt,hostfwd=tcp::20021-:22
```

