#!/usr/bin/env bash

k_ver="6.0.2"
k_src="https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-${k_ver}.tar.xz"

b_ver="1.33.2"
b_src="https://busybox.net/downloads/busybox-${b_ver}.tar.bz2"

if [[ ! -d outputs ]]; then
	mkdir outputs
fi

if [[ ! -f outputs/bzImage ]]; then
	[[ ! -f linux-${k_ver}.tar.xz ]] && wget $k_src
	[[ -d linux-${k_ver} ]] && rm -rf linux-${k_ver}
	tar -xvf linux-${k_ver}.tar.xz
	cp kernel-config linux-${k_ver}/.config
	pushd linux-${k_ver}
	make olddefconfig
	make menuconfig
	cp .config ../kernel-config
	make -j$(nproc)
	cp arch/x86/boot/bzImage ../outputs/.
	popd	
fi

if [[ ! -f outputs/busybox ]]; then
	[[ ! -f busybox-${b_ver}.tar.bz2 ]] && wget $b_src && 
	[[ -d busybox-${b_ver} ]] && rm -rf busybox-${b_ver}
	tar -xvf busybox-${b_ver}.tar.bz2
	cp bb-config busybox-${b_ver}/.config
	pushd busybox-${b_ver}
	[[ ! -d kernel-headers ]] && git clone https://github.com/sabotage-linux/kernel-headers
	make menuconfig
	make CC=musl-gcc
	cp busybox ../outputs/.
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
