#!/bin/bash

set -u

# ----- ----- ----- -----
# 编译 qt5 源码
# Arch: x86
# Linux: Ubuntu 20.04
# ----- ----- ----- -----

checkenv() {
  # Build options
  sudo apt install -y flex bison build-essential
  
  ccache 1> /dev/null 2> /dev/null
  if [ $? -eq 127 ]; then sudo apt install -y ccache
  fi
  ccache --version | head --lines=1

  # Support enabled for pkg-config, udev, zlib
  sudo apt install -y libudev-dev

  sudo apt install -y \
	  libgl1-mesa-dev libglu1-mesa-dev libegl1-mesa-dev \
	  freeglut3-dev \
	  libxkbcommon-x11-dev libxkbcommon-dev \
	  libxrender-dev 
  
  # Qt GUi and Further Image Formats
  sudo apt install -y \
    libjpeg-dev libpng-dev libmd4c-dev \
    libwebp-dev libfreetype-dev

  # TODO: openGL Vulkan

  # system libs for qpa-xcb
  sudo apt install -y \
    libxcb* \
	  libxcursor-dev libx11-dev libx11-xcb-dev \
	  libxi-dev \
	  libdrm-dev

  # gperf need for QtPdf
  sudo apt install -y gperf
  gperf --version | head --lines=1

  # QtWebEngine required: nss dbus
  sudo apt install -y libnss*-dev libdbus-1-dev
}

# param: $1 pkgName 
#        $2 dirName
tarQt5() {
  echo "start tar -xf $1, wait a minute..."
  rm -rf $2
  mkdir $2
  tar -xf $1 -C $2 --strip-components 1
  echo "tar end! Qt5 source in dir $2/"
}

install_nodejs() {
  sudo apt install -y ca-certificates curl gnupg
  curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | \
	  sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
  echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" | \
    sudo tee /etc/apt/sources.list.d/nodesource.list
  sudo apt update
  sudo apt install -y nodejs
}

# C lib, provide touchscreen events
#
install_tslib() {
  local content=`sudo find /usr/ -name tslib.h`
  if test $content; then return 0;
  fi

  sudo apt install -y autoconf automake libtool

  ver=1.22
  pkgName=tslib-$ver.tar.xz
  if [ ! -f $pkgName ]; then
    wget --no-verbose \
        https://github.com/libts/tslib/releases/download/$ver/$pkgName
  fi
  tar -xf $pkgName

  cd tslib-$ver
  sudo ./autogen.sh
  ./configure
  make
  sudo make install
  cd ..
}

# ----- ----- main() ----- -----
checkenv

ver="5.15.6" # publish at 2022.9
pkgName=qt-everywhere-opensource-src-$ver.tar.xz

install_tslib

#install_nodejs
sudo apt autoremove -y

if [ ! -f $pkgName ]; then
  wget --no-verbose -O $pkgName \
	  https://download.qt.io/archive/qt/5.15/$ver/single/$pkgName # 594M+
else
  echo "qt $ver have downloaded!"
fi

op=0
if [ ! -d Qt5 ]; then tarQt5 $pkgName Qt5
else
  read -p "Qt5 have exist! tar it again? [Y/n] " op
  case $op in
    Y | y | 1) rm -rf Qt5
	    tarQt5 $pkgName Qt5;;
    *) echo "本次不解压, 直接用之前解压的内容。"
  esac
fi

du -sh Qt5/
printf "%0.s----- " {1..9}

# 在配置时加入 -opensource 和 -confirm-license 免除自选
# echo -e "\n接下来有两次选项，第一次直接按 o, 第二次直接按 y, 切记!"

cd Qt5/
rm -rf config.cache

./configure -opensource -confirm-license \
  -xcb \
  -tslib \
  -qt-libpng -qt-libjpeg \
	-no-opengl \
  -no-openssl \
  -no-glib

op=0
read -p "start make -jx? [Y/n] " op 
case $op in
  Y | y | 1) make -j1 V=s;;
  2) make -j2;;
  4) make -j4;;
  8) make -j8;;
  *) echo "config ok, you can make now!"; exit
esac

sudo make install

# test
qmake -v

cd ..
