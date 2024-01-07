#!/bin/bash

set -u

# ----- ----- ----- -----
# install qemu v8+ with source
# Arch: x86
# Linux: Ubuntu 22.04
#
# Usage: just modify the value of verWant
# ----- ----- ----- -----

# prere: gcc make flex bison
#        install 4 tools above with your hands !
check_env() {
  flex --version
  if [ $? -eq 127 ]; then exit;
  fi 

  sudo apt install -y libtool ninja-build pkg-config

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

# get tar from local directory /opt or download again
#
getpkg_qemu() {
  local tarList=()
  local tarCheck=0
  # e.g. /opt/qemu-8.2.1.tar.bz2
  for pkg in /opt/*
  do
    local pkgName=`basename $pkg`
    if [[ ${pkgName%-*} == "qemu" ]]; then tarList+=($pkg)
    fi
    if [[ $pkgName == $tarWant ]]; then tarCheck=1
    fi
  done

  local len=${#tarList[@]}
  echo "find $len related package in local, best one in them is: "
  du -sh ${tarList[$len-1]}
  
  echo -e "\033[36m ----- ----- ----- ----- ----- ----- \033[0m"
  if [ $tarCheck -eq 1 ]; then echo "package which you want have existed: "
    du -sh /opt/$tarWant
    return 0
  fi
 
  local op=0
  read -p "Do you want download the package: $tarWant ? [Y/n] " op
  case $op in
    Y | y | 1) sudo wget --directory-prefix /opt \
	https://download.qemu.org/$tarWant ;;
    *) tarWant=`basename ${tarList[$len-1]}`
  esac
}

install_qemu() {
  local pkg="qemu-8.2.0.tar.bz2"
  if [ $# -eq 1 ]; then pkg=$1
  fi
  local pkgDir=${pkg%.tar*}
  
  # extract it to current path
  if [ ! -d $pkgDir ]; then tar -xjf /opt/$pkg -C .
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

# ----- ----- main ----- -----
check_env

pos=`pwd`

verWant="8.2.1" # you can modify it !
tarWant="qemu-$verWant.tar.bz2"

getpkg_qemu

echo "$tarWant will be used!" 
install_qemu $tarWant

cd $pos

# test
qemu-system-arm --version
