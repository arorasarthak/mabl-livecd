#!/bin/bash
set -eu -o pipefail

ROOT_PATH=$(pwd)
WORKING_PATH="${ROOT_PATH}/livecdtmp"
ISO_FILE="xubuntu-20.04.1-desktop-amd64.iso"
CHROOT_TEMP_PATH="${ROOT_PATH}/squashfs-root/tmp"

sudo apt install squashfs-tools genisoimage
sudo apt -y install xorriso isolinux

rm -rf xubuntu4mabl.iso

if [ -d squashfs-root ]; then
  rm -rf squashfs-root
fi

if [ -d customiso ]; then
  rm -rf customiso
fi

if [ -d /mnt/iso ]; then
  rm -rf /mnt/iso
fi

sudo mkdir /mnt/iso

sudo mount "$ISO_FILE" /mnt/iso
mkdir customiso
sudo rsync -a --exclude=casper/filesystem.squashfs /mnt/iso/ customiso/

sudo unsquashfs /mnt/iso/casper/filesystem.squashfs
sudo umount /mnt/iso

echo >&2 ">>>>>> Entering chroot "
mount --bind /dev squashfs-root/dev
mount --bind /run squashfs-root/run
cp -a "${ROOT_PATH}/files" "${CHROOT_TEMP_PATH}/."
chroot squashfs-root /bin/bash -c "/tmp/files/chroot-build.sh"

sudo umount squashfs-root/dev/
sudo umount squashfs-root/run/
#sudo rm customiso/casper/filesystem.squashfs
echo >&2 ">>>>>> Compressing Filesystem "
sudo mksquashfs squashfs-root customiso/casper/filesystem.squashfs -comp xz #-e squashfs-root/boot
cd customiso
sudo rm md5sum.txt
sudo find -type f -print0 | xargs -0 sudo md5sum | grep -Ev "./md5sum.txt|./isolinux/" | sudo tee md5sum.txt
cd -

echo >&2 ">>>>>> Building ISO "
sudo xorriso -as mkisofs \
  -r -V "XUBUNTU4MABL" -R -l -o xubuntu4mabl.iso \
  -c isolinux/boot.cat -b isolinux/isolinux.bin \
  -no-emul-boot -boot-load-size 4 -boot-info-table \
  -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
  -eltorito-alt-boot \
  -e boot/grub/efi.img \
  -no-emul-boot -isohybrid-gpt-basdat customiso/

sudo chown $(id -u):$(id -g) xubuntu4mabl.iso

if [ -d squashfs-root ]; then
  rm -rf squashfs-root
fi

if [ -d customiso ]; then
  rm -rf customiso
fi

if [ -d /mnt/iso ]; then
  rm -rf /mnt/iso
fi

#chmod +w extract-cd/casper/filesystem.manifest
#sudo su
#chroot edit dpkg-query -W --showformat='${Package} ${Version}\n' > extract-cd/casper/filesystem.manifest

#sudo cp extract-cd/casper/filesystem.manifest extract-cd/casper/filesystem.manifest-desktop
#sudo sed -i '/ubiquity/d' extract-cd/casper/filesystem.manifest-desktop
#sudo sed -i '/casper/d' extract-cd/casper/filesystem.manifest-desktop

#sudo rm extract-cd/casper/filesystem.squashfs
#sudo mksquashfs edit extract-cd/casper/filesystem.squashfs -comp xz -e edit/boot
#sudo su
#printf $(du -sx --block-size=1 edit | cut -f1) > extract-cd/casper/filesystem.size


#cd extract-cd
#sudo rm md5sum.txt
#find -type f -print0 | sudo xargs -0 md5sum | grep -v isolinux/boot.cat | sudo tee md5sum.txt
#sudo mkisofs -D -r -V "$IMAGE_NAME" -cache-inodes -J -l -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -o ../mabl-custom.iso .
