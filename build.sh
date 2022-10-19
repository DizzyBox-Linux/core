#!/usr/bin/env bash

set -ex

k_ver="6.0.2"
k_src="https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-${k_ver}.tar.xz"

b_ver="1.33.2"
b_src="https://busybox.net/downloads/busybox-${b_ver}.tar.bz2"

LIMINE_VER="3.20.1"
LIMINE_SRC="https://github.com/limine-bootloader/limine/releases/download/v${LIMINE_VER}/limine-${LIMINE_VER}.tar.gz"

if [[ ! -d outputs ]]; then
	mkdir outputs
fi

if [[ ! -f outputs/bzImage ]]; then
	if [[ ! -f linux-${k_ver}.tar.xz ]]; then
		wget $k_src
		tar -xf linux-${k_ver}.tar.xz
	fi

	ls | grep kernel-config
	printf "kconfig filename (or blank for defconfig): "
	read cfg

	pushd linux-${k_ver}
	if [[ ! "$cfg" == "" ]]; then
		cp ../$cfg .config
		make oldconfig
	else
		make defconfig
	fi
	make menuconfig
	cp .config ../kernel-config-last
	sed -i 's/=m/=y/g' .config
	make -j$(nproc)
	cp arch/x86/boot/bzImage ../outputs/.
	cp System.map ../outputs/.
	popd	
fi

if [[ ! -f outputs/busybox ]]; then
	[[ ! -f busybox-${b_ver}.tar.bz2 ]] && wget $b_src && 
	[[ -d busybox-${b_ver} ]] && rm -rf busybox-${b_ver}
	tar -xf busybox-${b_ver}.tar.bz2
	cp bb-config busybox-${b_ver}/.config
	pushd busybox-${b_ver}
	[[ ! -d kernel-headers ]] && git clone https://github.com/sabotage-linux/kernel-headers
	make menuconfig
	make CC=musl-gcc
	cp busybox ../outputs/.
	popd
fi

if [[ ! -f outputs/limine.sys ]]; then
	[[ -d limine-${LIMINE_VER} ]] && rm -rf limine-${LIMINE_VER}*
	wget $LIMINE_SRC
	tar -xf limine*
	pushd limine-${LIMINE_VER}
	CC=musl-gcc ./configure --enable-bios --enable-uefi-x86_64 --enable-limine-deploy
	make
	cp bin/limine{-deploy,.sys} ../outputs/.
	popd
fi

fallocate -l200M image

(
	echo "o"
	echo "n"
	echo
	echo
	echo
	echo
	echo "w"
) | fdisk image

echo "now run finish_image.sh as root"
