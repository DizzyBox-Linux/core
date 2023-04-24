#!/usr/bin/env bash
export PATH=/sbin/:$PATH

set -ex

k_ver="6.2.12"
k_src="https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-${k_ver}.tar.xz"

b_ver="1.33.2"
b_src="https://busybox.net/downloads/busybox-${b_ver}.tar.bz2"

LIMINE_VER="4.20230414.0"
LIMINE_SRC="https://github.com/limine-bootloader/limine/releases/download/v${LIMINE_VER}/limine-${LIMINE_VER}.tar.gz"

GRUB_VER="2.06"
GRUB_SRC="https://ftp.gnu.org/gnu/grub/grub-${GRUB_VER}.tar.xz"

GLIBC_VER="2.37"
GLIBC_SRC="https://ftp.gnu.org/gnu/glibc/glibc-${GLIBC_VER}.tar.xz"

if [[ ! -d outputs ]]; then
	mkdir outputs
fi

if [[ ! -f outputs/bzImage ]]; then
	if [[ ! -f linux-${k_ver}.tar.xz ]]; then
		wget $k_src
	fi

	[[ ! -d linux-${k_ver} ]] && tar -xvf linux-${k_ver}.tar.xz

	ls kernel-configs
	printf "kconfig filename (or blank for defconfig): "
	read cfg

	pushd linux-${k_ver}
	if [[ ! "$cfg" == "" ]]; then
		cp ../kernel-configs/$cfg .config
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
	make CC=musl-gcc -j$(nproc)
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
	cp bin/BOOTX64.EFI ../outputs/.
	popd
fi

if [[ ! -f outputs/glibc-done ]]; then
	[[ -d glibc-${GLIBC_VER} ]] && rm -rf glibc-${GLIBC_VER}
	[[ ! -f glibc-${GLIBC_VER}.tar.xz ]] && wget $
	[[ ! -d outputs/glibc ]] && mkdir -p outputs/glibc
	dest="$(pwd)/outputs/glibc"
	tar -xvf glibc-${GLIBC_VER}.tar.xz
	pushd glibc-${GLIBC_VER}
	mkdir build && pushd build
	../configure --prefix=/usr
	make -j$(nproc)
	make install DESTDIR=$dest
	popd
	popd
	touch outputs/glibc-done
fi

if [[ ! -f outputs/grub-installed ]]; then
	[[ -d grub-${GRUB_VER} ]] && rm -rf grub-${GRUB_VER}
	[[ ! -f grub-${GRUB_VER}.tar.xz ]] && wget $GRUB_SRC
	[[ ! -d outputs/grub-stuff ]] && mkdir -p outputs/grub-stuff
	tar -xvf grub-${GRUB_VER}.tar.xz
	dest="$(pwd)/outputs/grub-stuff"
	pushd grub-${GRUB_VER}
	./configure --prefix=/usr
	make -j$(nproc)
	make install DESTDIR=$dest
	touch ../outputs/grub-installed
	popd
fi

fallocate -l2048M image

if [[ "$BM" == "EFI" ]]; then
	(
		echo "g"
		echo "n"
		echo
		echo
		echo "+500M"
		echo "t"
		echo
		echo "1"
		echo "n"
		echo
		echo
		echo
		echo "w"
	) | fdisk image
else
	(
		echo "o"
		echo "n"
		echo
		echo
		echo
		echo
		echo "w"
	) | fdisk image
fi

echo "now run finish_image.sh as root"
