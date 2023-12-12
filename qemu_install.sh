#!/bin/bash

set -u

# prere: make flex bison
check_env() {
  sudo apt install -y libtool \
      make ninja-build pkg-config

  sudo apt install -y	python3-pip \
      python3-sphinx python3-venv python*-capstone

  pip install sphinx-rtd-theme

  sudo apt install -y \
      build-essential zlib1g-dev libglib2.0-dev binutils-dev \
      libboost-all-dev autoconf \
      libssl-dev libpixman-1-dev

  # UI
  sudo apt install -y libjpeg-dev libpng-dev 

  # Dependencies
  sudo apt install -y libtasn1-dev \
      libiscsi-dev libudev-dev \
      libusb-dev libusb-1*-dev \
      libzstd-dev libdw-dev
}

install_qemu() {
  local ver="8.1.3"
  if [ $# -eq 1 ]; then ver=$1
  fi

  local pkgDir="qemu-$ver"
  if [ ! -d $pkgDir ]; then
    wget --no-verbose \
	https://download.qemu.org/$pkgDir.tar.bz2 # 143M
    tar -xjf $pkgDir.tar.bz2
  fi
  cd $pkgDir
  du -sh .
  ./configure
  
  local op=0
  read -p "start make -jx? [Y/n] " op 
  case $op in
    Y | y | 1) make -j1 V=s;;
    2) make -j2;;
    4) make -j4;;
    *) echo "config ok, you can make now!"
      return 0
  esac

  sudo make install
  cd ..
}

check_env

pos=`pwd`
install_qemu "8.1.3"
cd $pos

# test
qemu-system-arm --version
