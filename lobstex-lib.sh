#!/bin/bash

apt-get update && apt-get install sudo && \
sudo apt-get install build-essential software-properties-common -y && \
sudo add-apt-repository ppa:ubuntu-toolchain-r/test -y && \
sudo add-apt-repository ppa:george-edison55/cmake-3.x -y && \
sudo apt-get update && \
sudo apt-get install gcc-snapshot -y && \
sudo apt-get update && \
sudo apt-get install gcc-6 g++-6 -y && \
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-6 60 --slave /usr/bin/g++ g++ /usr/bin/g++-6 && \
sudo apt-get install gcc-4.8 g++-4.8 -y && \
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-4.8 40 --slave /usr/bin/g++ g++ /usr/bin/g++-4.8 && \
sudo update-alternatives --config gcc && \
sudo apt-get update && \
sudo apt-get install cmake -y;


wget https://github.com/lobstex/lobstex2.3/releases/download/v2.3/Linux-masternode.zip
unzip Linux-masternode.zip
cd Linux-masternode
chmod u+x lobstexd
chmod u+x lobstex-cli
./lobstexd -daemon
