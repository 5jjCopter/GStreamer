#!/bin/bash --debugger
set -e

[ -n "$1" ] && BRANCH=$1

# Create a log file of the build as well as displaying the build on the tty as it runs
exec > >(tee build_gstreamer.log)
exec 2>&1

# Update and Upgrade the Pi, otherwise the build may fail due to inconsistencies
grep -q BCM2708 /proc/cpuinfo && sudo apt-get update && sudo apt-get upgrade -y --force-yes

# Get the required libraries
sudo apt-get install -y --force-yes build-essential autotools-dev automake autoconf \
                                    libtool autopoint libxml2-dev zlib1g-dev libglib2.0-dev \
                                    pkg-config bison flex python3 git gtk-doc-tools libasound2-dev \
                                    libgudev-1.0-dev libxt-dev libvorbis-dev libcdparanoia-dev \
                                    libpango1.0-dev libtheora-dev libvisual-0.4-dev iso-codes \
                                    libgtk-3-dev libraw1394-dev libiec61883-dev libavc1394-dev \
                                    libv4l-dev libcairo2-dev libcaca-dev libspeex-dev libpng-dev \
                                    libshout3-dev libjpeg-dev libaa1-dev libflac-dev libdv4-dev \
                                    libtag1-dev libwavpack-dev libpulse-dev libsoup2.4-dev libbz2-dev \
                                    libcdaudio-dev libdc1394-22-dev ladspa-sdk libass-dev \
                                    libcurl4-gnutls-dev libdca-dev libdirac-dev libdvdnav-dev \
                                    libexempi-dev libexif-dev libfaad-dev libgme-dev libgsm1-dev \
                                    libiptcdata0-dev libkate-dev libmimic-dev libmms-dev \
                                    libmodplug-dev libmpcdec-dev libofa0-dev libopus-dev \
                                    librsvg2-dev librtmp-dev libschroedinger-dev libslv2-dev \
                                    libsndfile1-dev libsoundtouch-dev libspandsp-dev libx11-dev \
                                    libxvidcore-dev libzbar-dev libzvbi-dev liba52-0.7.4-dev \
                                    libcdio-dev libdvdread-dev libmad0-dev libmp3lame-dev \
                                    libmpeg2-4-dev libopencore-amrnb-dev libopencore-amrwb-dev \
                                    libsidplay1-dev libtwolame-dev libx264-dev libusb-1.0 \
                                    python-gi-dev yasm python3-dev libgirepository1.0-dev \
                                    libegl1-mesa-dev libgles2-mesa-dev

# get the repos if they're not already there
cd $HOME
[ ! -d src ] && mkdir src
cd src

# get repos if they are not there yet
[ ! -d gstreamer ] && git clone git://anongit.freedesktop.org/git/gstreamer/gstreamer
[ ! -d gst-plugins-base ] && git clone git://anongit.freedesktop.org/git/gstreamer/gst-plugins-base
[ ! -d gst-plugins-good ] && git clone git://anongit.freedesktop.org/git/gstreamer/gst-plugins-good
[ ! -d gst-plugins-bad ] && git clone git://anongit.freedesktop.org/git/gstreamer/gst-plugins-bad
[ ! -d gst-plugins-ugly ] && git clone git://anongit.freedesktop.org/git/gstreamer/gst-plugins-ugly
[ ! -d gst-libav ] && git clone git://anongit.freedesktop.org/git/gstreamer/gst-libav
[ ! -d gst-omx ] && git clone git://anongit.freedesktop.org/git/gstreamer/gst-omx
[ ! -d gst-python ] && git clone git://anongit.freedesktop.org/git/gstreamer/gst-python
[ ! -d gst-rpicamsrc ] && git clone https://github.com/thaytan/gst-rpicamsrc.git
[ ! -d libvpx ] && git clone http://git.chromium.org/webm/libvpx.git

# VPX support
cd libvpx
git checkout -t origin/$BRANCH || true
sudo make uninstall || true
git pull
./configure
make
make install
cd ..

#Gstreamer
export LD_LIBRARY_PATH=/usr/local/lib/
cd gstreamer
git checkout -t origin/$BRANCH || true
sudo make uninstall || true
git pull
./autogen.sh --disable-gtk-doc
make
sudo make install
cd ..

# Gstreamer Plugins Base
cd gst-plugins-base
git checkout -t origin/$BRANCH || true
sudo make uninstall || true
git pull
./autogen.sh --disable-gtk-doc
make
sudo make install
cd ..

# Gstreamer Plugins Good
cd gst-plugins-good
git checkout -t origin/$BRANCH || true
sudo make uninstall || true
git pull
./autogen.sh --disable-gtk-doc
make
sudo make install
cd ..

# Gstreamer Plugins Ugly
cd gst-plugins-ugly
git checkout -t origin/$BRANCH || true
sudo make uninstall || true
git pull
./autogen.sh --disable-gtk-doc
make
sudo make install
cd ..

# Gstreamer Libav
cd gst-libav
git checkout -t origin/$BRANCH || true
sudo make uninstall || true
git pull
./autogen.sh --disable-gtk-doc
make
sudo make install
cd ..

# Gstreamer Plugins Bad
cd gst-plugins-bad
git checkout -t origin/$BRANCH || true
sudo make uninstall || true
git pull
export LDFLAGS='-L/opt/vc/lib' \
CFLAGS='-I/opt/vc/include -I/opt/vc/include/interface/vcos/pthreads -I/opt/vc/include/interface/vmcs_host/linux' \
CPPFLAGS='-I/opt/vc/include -I/opt/vc/include/interface/vcos/pthreads -I/opt/vc/include/interface/vmcs_host/linux'
./autogen.sh --disable-gtk-doc --disable-examples --disable-x11 --disable-glx --disable-glx --disable-opengl
make CFLAGS+="-Wno-error -Wno-redundant-decls -I/opt/vc/include -I/opt/vc/include/interface/vcos/pthreads -I/opt/vc/include/interface/vmcs_host/linux" \
  CPPFLAGS+="-Wno-error -Wno-redundant-decls -I/opt/vc/include -I/opt/vc/include/interface/vcos/pthreads -I/opt/vc/include/interface/vmcs_host/linux" \
  CXXFLAGS+="-Wno-redundant-decls" LDFLAGS+="-L/opt/vc/lib"
sudo make install
cd ..

# Python bindings
cd gst-python
git checkout -t origin/$BRANCH || true
export LD_LIBRARY_PATH=/usr/local/lib/ 
sudo make uninstall || true
git pull
PYTHON=/usr/bin/python3 ./autogen.sh
make
sudo make install
cd ..

# OMX support
cd gst-omx
sudo make uninstall || true
git pull
export LDFLAGS='-L/opt/vc/lib' \
CFLAGS='-I/opt/vc/include -I/opt/vc/include/IL -I/opt/vc/include/interface/vcos/pthreads -I/opt/vc/include/interface/vmcs_host/linux -I/opt/vc/include/IL' \
CPPFLAGS='-I/opt/vc/include -I/opt/vc/include/IL -I/opt/vc/include/interface/vcos/pthreads -I/opt/vc/include/interface/vmcs_host/linux -I/opt/vc/include/IL'
./autogen.sh --disable-gtk-doc --with-omx-target=rpi
# fix for glcontext errors and openexr redundant declarations
make CFLAGS+="-Wno-error -Wno-redundant-decls" LDFLAGS+="-L/opt/vc/lib"
sudo make install
cd ..

# Gstreamer Raspberry Pi Camera Wrapper
cd gst-rpicamsrc
sudo make uninstall || true
git pull
./autogen.sh --prefix=/usr --libdir=/usr/lib/arm-linux-gnueabihf/
sudo make
sudo make install
cd ..
