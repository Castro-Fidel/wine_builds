#!/usr/bin/env bash

## A script for creating DEBIAN bootstraps for Wine compilation.
##
## debootstrap and perl are required
## root rights are required
##
## About 5.5 GB of free space is required
## And additional 2.5 GB is required for Wine compilation

if [ "$EUID" != 0 ]; then
	echo "This script requires root rights!"
	exit 1
fi

if ! command -v debootstrap 1>/dev/null || ! command -v perl 1>/dev/null; then
	echo "Please install debootstrap and perl and run the script again"
	exit 1
fi

# Keep in mind that although you can choose any version of Ubuntu/Debian
# here, but this script has only been tested with Ubuntu 18.04 Bionic
export CHROOT_DISTRO="bullseye"
# export CHROOT_MIRROR="https://deb.debian.org/debian"
# export CHROOT_MIRROR="http://debian.mirror.vu.lt/debian/"
export CHROOT_MIRROR="http://mirror.yandex.ru/debian"

# Set your preferred path for storing chroots
# Also don't forget to change the path to the chroots in the build_wine.sh
# script, if you are going to use it
export MAINDIR_CHROOTS="/opt/chroots_${CHROOT_DISTRO}"
export CHROOT_X64="${MAINDIR_CHROOTS}"/${CHROOT_DISTRO}_x86_64_chroot
mkdir -p "${CHROOT_X64}"

prepare_chroot () {

	CHROOT_PATH="${CHROOT_X64}"

	echo "Unmount chroot directories. Just in case."
	umount -Rl "${CHROOT_PATH}"

	echo "Mount directories for chroot"
	mount --bind "${CHROOT_PATH}" "${CHROOT_PATH}"
	mount -t proc /proc "${CHROOT_PATH}"/proc
	mount --bind /sys "${CHROOT_PATH}"/sys
	mount --make-rslave "${CHROOT_PATH}"/sys
	mount --bind /dev "${CHROOT_PATH}"/dev
	mount --bind /dev/pts "${CHROOT_PATH}"/dev/pts
	mount --bind /dev/shm "${CHROOT_PATH}"/dev/shm
	mount --make-rslave "${CHROOT_PATH}"/dev

	rm -f "${CHROOT_PATH}"/etc/resolv.conf
	cp /etc/resolv.conf "${CHROOT_PATH}"/etc/resolv.conf

	echo "Chrooting into ${CHROOT_PATH}"
	chroot "${CHROOT_PATH}" /usr/bin/env LANG=en_US.UTF-8 TERM=xterm PATH="/bin:/sbin:/usr/bin:/usr/sbin" /opt/prepare_chroot.sh

	echo "Unmount chroot directories"
	umount -l "${CHROOT_PATH}"
	umount "${CHROOT_PATH}"/proc
	umount "${CHROOT_PATH}"/sys
	umount "${CHROOT_PATH}"/dev/pts
	umount "${CHROOT_PATH}"/dev/shm
	umount "${CHROOT_PATH}"/dev
}

create_build_scripts () {

	cat <<EOF > "${MAINDIR_CHROOTS}"/prepare_chroot.sh
#!/bin/bash

apt-get update
apt-get -y install nano
apt-get -y install locales
echo ru_RU.UTF_8 UTF-8 >> /etc/locale.gen
echo en_US.UTF_8 UTF-8 >> /etc/locale.gen
locale-gen
# echo deb '${CHROOT_MIRROR}' ${CHROOT_DISTRO} main universe > /etc/apt/sources.list
# echo deb '${CHROOT_MIRROR}' ${CHROOT_DISTRO}-updates main universe >> /etc/apt/sources.list
# echo deb '${CHROOT_MIRROR}' ${CHROOT_DISTRO}-security main universe >> /etc/apt/sources.list
# echo deb-src '${CHROOT_MIRROR}' ${CHROOT_DISTRO} main universe >> /etc/apt/sources.list
# echo deb-src '${CHROOT_MIRROR}' ${CHROOT_DISTRO}-updates main universe >> /etc/apt/sources.list
# echo deb-src '${CHROOT_MIRROR}' ${CHROOT_DISTRO}-security main universe >> /etc/apt/sources.list
apt-get update
apt-get -y upgrade
apt-get -y dist-upgrade
apt-get -y install software-properties-common
dpkg --add-architecture i386
apt-get update
# Wine dependencies
apt-get install -y gcc gcc-mingw-w64-x86-64 gcc-mingw-w64-i686 gcc-multilib \
                git sudo autoconf flex bison perl gettext \
                libasound2-dev:amd64 libasound2-dev:i386 \
                libcapi20-dev:amd64 libcapi20-dev:i386 \
                libcups2-dev:amd64 libcups2-dev:i386 \
                libdbus-1-dev:amd64 libdbus-1-dev:i386 \
                libfontconfig-dev:amd64 libfontconfig-dev:i386 \
                libfreetype-dev:amd64 libfreetype-dev:i386 \
                libgl1-mesa-dev:amd64 libgl1-mesa-dev:i386 \
                libgnutls28-dev:amd64 libgnutls28-dev:i386 \
                libgphoto2-dev:amd64 libgphoto2-dev:i386 \
                libice-dev:amd64 libice-dev:i386 \
                libkrb5-dev:amd64 libkrb5-dev:i386 \
                libosmesa6-dev:amd64 libosmesa6-dev:i386 \
                libpcap-dev:amd64 libpcap-dev:i386 \
                libpcsclite-dev:amd64 \
                libpulse-dev:amd64 libpulse-dev:i386 \
                libsane-dev:amd64 libsane-dev:i386 \
                libsdl2-dev:amd64 libsdl2-dev:i386 \
                libudev-dev:amd64 libudev-dev:i386 \
                libusb-1.0-0-dev:amd64 libusb-1.0-0-dev:i386 \
                libv4l-dev:amd64 libv4l-dev:i386 \
                libvulkan-dev:amd64 libvulkan-dev:i386 \
                libwayland-dev:amd64 libwayland-dev:i386 \
                libx11-dev:amd64 libx11-dev:i386 \
                libxcomposite-dev:amd64 libxcomposite-dev:i386 \
                libxcursor-dev:amd64 libxcursor-dev:i386 \
                libxext-dev:amd64 libxext-dev:i386 \
                libxi-dev:amd64 libxi-dev:i386 \
                libxinerama-dev:amd64 libxinerama-dev:i386 \
                libxrandr-dev:amd64 libxrandr-dev:i386 \
                libxrender-dev:amd64 libxrender-dev:i386 \
                libxxf86vm-dev:amd64 libxxf86vm-dev:i386 \
                linux-libc-dev:amd64 linux-libc-dev:i386 \
                ocl-icd-opencl-dev:amd64 ocl-icd-opencl-dev:i386 \
                samba-dev:amd64 \
                unixodbc-dev:amd64 unixodbc-dev:i386 \
                gudev-1.0:amd64 gudev-1.0:i386 \
                libgcrypt-dev libgpg-error-dev \
                x11proto-dev

# More wine dependencies
apt-get install -y ccache netbase curl ca-certificates \
				xserver-xorg-video-dummy xserver-xorg xfonts-base xinit fvwm \
				winbind fonts-liberation2 fonts-noto-core fonts-noto-cjk pulseaudio

# Gstreamer codecs

curl -O https://www.deb-multimedia.org/pool/main/d/deb-multimedia-keyring/deb-multimedia-keyring_2016.8.1_all.deb
dpkg -i deb-multimedia-keyring_2016.8.1_all.deb
echo 'deb https://www.deb-multimedia.org bullseye main' >> /etc/apt/sources.list
rm deb-multimedia-keyring_2016.8.1_all.deb

apt-get update
apt-get install -y libgstreamer-plugins-base1.0-dev:amd64 libgstreamer-plugins-base1.0-dev:i386 \
                    libasound2-plugins:amd64 libasound2-plugins:i386 \
                    libmjpegutils-2.1-0:amd64 libmjpegutils-2.1-0:i386 \
                    gstreamer1.0-libav:amd64 gstreamer1.0-libav:i386 \
                    gstreamer1.0-plugins-base:amd64 gstreamer1.0-plugins-good:amd64 \
                    gstreamer1.0-plugins-bad:amd64 gstreamer1.0-plugins-ugly:amd64 \
                    gstreamer1.0-plugins-base:i386 gstreamer1.0-plugins-good:i386 \
                    gstreamer1.0-plugins-bad:i386 gstreamer1.0-plugins-ugly:i386

# Misc utilities (not sure if fontconfig is required)
apt-get -y install wget build-essential vim nano fontconfig autoreconf flex

# Runtime dependencies
apt-get -y install lsb-release
apt-get clean

EOF

	chmod +x "${MAINDIR_CHROOTS}"/prepare_chroot.sh
	echo "MAINDIR_CHROOTS=${MAINDIR_CHROOTS}"
	mv "${MAINDIR_CHROOTS}"/prepare_chroot.sh "${CHROOT_X64}"/opt
}

rsync -avz --progress keyring.debian.org::keyrings/keyrings/ /usr/share/keyrings/

debootstrap --arch amd64 $CHROOT_DISTRO "${CHROOT_X64}" $CHROOT_MIRROR
[[ "$?" != 0 ]] && echo "error: create 64_chroot" && exit 1

create_build_scripts

prepare_chroot 64

rm "${CHROOT_X64}"/opt/prepare_chroot.sh

echo "Done"
