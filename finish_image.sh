#!/usr/bin/env bash

export PATH=/sbin:/usr/sbin:$PATH

set -ex

LIMINE_VER="3.20.1"

if [[ ! "$EUID" == "0" ]]; then
	echo "Run as root"
	exit 1
fi

loopdev=$(losetup -P -f --show image)

if [[ "$BM" == "EFI" ]]; then
	mkfs.vfat ${loopdev}p1
	mkfs.ext4 ${loopdev}p2
else
	mkfs.ext4 ${loopdev}p1
fi

[[ -d mountpt ]] && rm -rf mountpt
mkdir mountpt

if [[ "$BM" == "EFI" ]]; then
	mount ${loopdev}p2 mountpt
else
	mount ${loopdev}p1 mountpt
fi

cd mountpt

mkdir -p usr/{sbin,bin} bin sbin boot

if [[ "$BM" == "EFI" ]]; then
	mkdir -p boot/efi
	mount ${loopdev}p1 boot/efi
fi

mkdir -p {dev,etc,home,lib,run,mnt,opt,proc,srv,sys}
mkdir -p var/{lib,lock,log,run,spool}
install -d -m 0750 root
install -d -m 1777 tmp
mkdir -p usr/{include,lib,share/udhcpc,src}

cp ../outputs/busybox usr/bin/busybox
cp ../outputs/bzImage boot/bzImage

if [[ "$BM" == "EFI" ]]; then
	cp ../outputs/BOOTX64.EFI boot/efi/.
fi

cp -r ../outputs/glibc/* .
cp -r ../outputs/grub-stuff/* .

for util in $(./usr/bin/busybox --list-full); do
  if [[ ! "$util" == "busybox" ]]; then
  	ln -s /usr/bin/busybox $util
  fi
done

cp -rv ../filesystem/etc/* etc/.
cp ../filesystem/usr/share/udhcpc/default.script usr/share/udhcpc/.
cp ../filesystem/boot/limine.cfg boot/.
mkdir -p boot/grub
cp ../filesystem/boot/grub.cfg boot/grub/.
cp ../outputs/limine.sys boot/.

cd ../

#cd mountpt
#partuuid=$(fdisk -l ../image | grep "Disk identifier" | awk '{split($0,a,": "); print a[2]}' | sed 's/0x//g')
#sed -i "s/something/${partuuid}-01/g" boot/limine.cfg
#cd ../

echo "(hd0) $loopdev" > mountpt/tmp/device.map

if [[ "$BM" == "EFI" ]]; then
	grub-install --target=x86_64-efi --grub-mkdevicemap=mountpt/tmp/device.map --efi-directory=mountpt/boot/efi --bootloader-id=Dizzy
else
	grub-install --target=i386-pc --recheck --boot-directory="mountpt/boot" "$loopdev"
fi

partuuid=$(fdisk -l image | grep "Disk identifier" | awk '{split($0,a,": "); print a[2]}' | sed 's/0x//g')
sed -i "s/something/${partuuid}-01/g" mountpt/boot/grub/grub.cfg

umount -R -l mountpt
rm -rf mountpt
losetup -D

#./outputs/limine-deploy ./image
