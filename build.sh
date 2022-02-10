#!/bin/bash

bash check_dependencies.sh

mkdir seed_imgs
wget seed_imgs/https://cloud-images.ubuntu.com/releases/bionic/release/ubuntu-18.04-server-cloudimg-amd64.img
wget seed_imgs/https://cloud-images.ubuntu.com/releases/focal/release/ubuntu-20.04-server-cloudimg-amd64.img

