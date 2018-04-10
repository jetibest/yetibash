#!/bin/bash

if [[ "$1" != "/dev/sd"* ]]
then
	echo "error: Please provide in the first argument the device (e.g. /dev/sdb). Do not include a partition number."
	exit
fi

SKIP_TO="" # "chroot"
INSTALL_DEVICE="$1"
INSTALL_MODE="$2"

INSTALL_BOOTPART="1"
INSTALL_FSPART="2"
INSTALL_DEVBOOT="${INSTALL_DEVICE}${INSTALL_BOOTPART}"
INSTALL_DEVFS="${INSTALL_DEVICE}${INSTALL_FSPART}"

if [[ "$INSTALL_MODE" == "chroot" ]]
then
	# Execute commands in chrooted environment
	
	read -p "Going to execute commands in chrooted enviroment. Continue? (y/n) " confirm
	if [[ "$confirm" != "y" ]]
	then
		exit
	fi
	
	echo "Please set the root password for the first time:"
	passwd
	
	# Install some basic packages we'll always need
	pacman --needed -Sy linux base base-devel vim grub efibootmgr arch-install-scripts dosfstools openssh dhcp parted
	
	echo "# Static information about the filesystems." > /etc/fstab
	echo "# See fstab(5) for details." >> /etc/fstab
	echo "" >> /etc/fstab
	echo "# <file system> <dir> <type> <options> <dump> <pass>" >> /etc/fstab
	echo "" >> /etc/fstab
	genfstab -U / >> /etc/fstab
	if [[ "$INSTALL_DEVBOOT" != "" ]]
	then
		sed -i -e 's#^'"$INSTALL_DEVBOOT"'#UUID='"$(blkid -o value -s UUID "$INSTALL_DEVBOOT")"'#' /etc/fstab
	fi
	if [[ "$INSTALL_DEVFS" != "" ]]
	then
		sed -i -e 's#^'"$INSTALL_DEVFS"'#UUID='"$(blkid -o value -s UUID "$INSTALL_DEVFS")"'#' /etc/fstab
	fi
	
	ln -sf /usr/share/zoneinfo/Europe/Amsterdam /etc/localtime
	hwclock --systohc
	locale-gen
	echo "LANG=en_US.UTF-8" > /etc/locale.conf
	echo "KEYMAP=dvorak" > /etc/vconsole.conf
	echo "ArchUSB" > /etc/hostname

	echo "Installing GRUB..."
	
	# Reformat boot partition, not even sure why
	if ! mkfs.fat -F 32 "$INSTALL_DEVBOOT"
	then
		echo "error: Boot filesystem not created."
		exit
	fi

        grub-install --target=x86_64-efi --efi-directory=/boot --removable
	#grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=arch_grub -> somehow EFI does not appear
	grub-mkconfig -o /boot/grub/grub.cfg

	echo "Finalizing with mkinitcpio -p linux..."

	mkinitcpio -p linux

	exit
fi

echo "Going to install Arch Linux on device: $INSTALL_DEVICE"
echo "There will be a boot partition on: $INSTALL_DEVBOOT"
echo "There will be a linux partition on: $INSTALL_DEVFS"

read -p "Do you want to continue installation? (y/n)" confirm
if [[ "$confirm" != "y" ]]
then
	exit
fi

if which pacman
then
  pacman --needed -Sy arch-install-scripts
fi

if [[ "$SKIP_TO" != "chroot" ]]
then

	parted "$INSTALL_DEVICE" mklabel gpt
	parted "$INSTALL_DEVICE" mkpart primary fat32 1MiB 512MiB
	parted "$INSTALL_DEVICE" mkpart primary ext4 512MiB 100%
	parted "$INSTALL_DEVICE" set 1 boot on
	parted "$INSTALL_DEVICE" set 1 esp on
	parted "$INSTALL_DEVICE" name 1 boot
	parted "$INSTALL_DEVICE" name 2 linux
	
	if ! [ -e "$INSTALL_DEVBOOT" ] || ! [ -e "$INSTALL_DEVFS" ]
	then
		echo "error: Partitions not created, stopping installation process."
		exit
	fi
	
	if ! mkfs.ext4 -F "$INSTALL_DEVFS"
	then
		echo "error: Linux filesystem not created."
		exit
	fi
	if ! mkfs.fat -F 32 "$INSTALL_DEVBOOT"
	then
		echo "error: Boot filesystem not created."
		exit
	fi
	
	if ! [ -d /mnt ]
	then
		mkdir /mnt
	fi
	result="$(mount "$INSTALL_DEVFS" /mnt 2>&1)"
	if [ $? -ne 0 ] && [[ "$result" != *"already mounted"* ]]
	then
		echo "error: Could not mount filesystem on /mnt."
		exit
	fi
	mkdir /mnt/boot
	result="$(mount "$INSTALL_DEVBOOT" /mnt/boot 2>&1)"
	if [ $? -ne 0 ] && [[ "$result" != *"already mounted"* ]]
	then
		echo "error: Could not mount boot partition on /mnt/boot."
	fi
	
  if which pacstrap
  then
    pacstrap /mnt
  else
	  if ! [ -f "arch-bootstrap.sh" ]
	  then
		  curl https://raw.githubusercontent.com/tokland/arch-bootstrap/master/arch-bootstrap.sh > /tmp/arch-bootstrap.sh
	  else
		  cp arch-bootstrap.sh /tmp/arch-bootstrap.sh
	  fi
	  if ! [ -f "get-pacman-dependencies.sh" ]
	  then
	  	curl https://raw.githubusercontent.com/tokland/arch-bootstrap/master/get-pacman-dependencies.sh > /tmp/get-pacman-dependencies.sh
	  else
	  	cp get-pacman-dependencies.sh /tmp/get-pacman-dependencies.sh
	  fi
  
	  if ! install -m 755 /tmp/arch-bootstrap.sh /usr/local/bin/arch-bootstrap
	  then
	  	echo "error: Installation of arch-bootstrap failed."
	  	exit
	  fi
	  if ! arch-bootstrap /mnt
	  then
	  	echo "error: Execution of arch-bootstrap failed on /mnt."
	  	exit
	  fi
  fi

fi # end of skip_to

# Ensure mounts:
if ! [ -d /mnt ]
then
	mkdir /mnt
fi
result="$(mount "$INSTALL_DEVFS" /mnt 2>&1)"
if [ $? -ne 0 ] && [[ "$result" != *"already mounted"* ]]
then
	echo "error: Could not mount filesystem on /mnt."
	exit
fi
mkdir /mnt/boot
result="$(mount "$INSTALL_DEVBOOT" /mnt/boot 2>&1)"
if [ $? -ne 0 ] && [[ "$result" != *"already mounted"* ]]
then
	echo "error: Could not mount boot partition on /mnt/boot."
fi

# Problem is, after chroot, we need to do more commands

cp -f "$(realpath $0)" /mnt/root/archinstallusb.sh

chrootcmd="chroot"
if which arch-chroot
then
  chrootcmd="arch-chroot"
  umount /mnt/proc
  umount /mnt/sys
  umount /mnt/dev
  umount /mnt/dev/pts
else
  mount --bind /proc /mnt/proc
  mount --bind /sys /mnt/sys
  mount --bind /dev /mnt/dev
  mount --bind /dev/pts /mnt/dev/pts
fi
if ! $chrootcmd /mnt /bin/bash -c "/root/archinstallusb.sh '$1' 'chroot'"
then
 	echo "error: Could not chroot into /mnt."
 	exit
fi

echo "Chroot exited."

rm /mnt/root/archinstallusb.sh

echo "Syncing..."

sync

echo "Sync complete."
read -p "Do you want to unmount and sync again now? (y/n) " confirm
if [[ "$confirm" == "y" ]]
then
	umount /mnt/proc
	umount /mnt/sys
	umount /mnt/dev/pts
	umount /mnt/dev
	umount /mnt/boot
	umount /mnt
	sync
fi

echo "Done."


#https://github.com/tokland/arch-bootstrap
#
#
#on the chrooted bash:
#    1  ls
#    2  pacman -S base base-devel
#    3  pacman -S vim
#    4  passwd
#    5  pacman -S grub arch-install-scripts
#    6  genfstab -U /
#    7  ln -sf /usr/share/zoneinfo/Europe/Amsterdam /etc/localtime
#    8  hwclock --systohc
#    9  locale-gen
#   10  vim /etc/locale.conf
#   11  vim /etc/vconsole.conf
#   12  echo �"YetiUSB2" > /etc/hostname
#   13  mkinitcpio -p linux
#   14  exit
#   15  genfstab -U /
#   16  cat /etc/fstab 
#   17  genfstab -U / >> /etc/fstab 
#   18  vim /etc/fstab 
#   19  ls -la /dev/disk/by-uuid
#   20  vim /etc/fstab 
#   21  vim /etc/fstab 
#   22  mkinitcpio -p linux
#   23  grub-install /dev/sdb
#   24  parted /dev/sdb
#   25  pacman -S parted
#   26  pacman -S gparted
#   27  gparted
#   28  parted
#   29  parted /dev/sdb
#   30  grub-install /dev/sdb
#   31  grub-mkconfig -o /boot/grub/grub.cfg 
#   32  grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=arch_grub
#   33  grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=arch_grub /dev/sdb
#   34  ls -la /dev/sdb*
#   35  ls -la /boot/
#   36  ls -la /boot/grub/
#   37  parted /dev/sdb print
#   38  grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=arch_grub /dev/sdb
#   39  grub-install /dev/sdb
#   40  mkfs.fat -F32 /dev/sdb1
#   41  pacman -S dosfstools
#   42  mkfs.fat -F32 /dev/sdb1
#   43  umount /dev/sdb1
#   44  mkfs.fat -F32 /dev/sdb1
#   45  mount /dev/sdb1 /boot
#   46  parted /dev/sdb print
#   47  parted /dev/sdb
#   48  parted /dev/sdb print
#   49  mkinitcpio -p linux
#   50  pacman -S linux
#   51  ls /boot
#   52  grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=arch_grub
#   53  pacman -S efibootmgr
#   54  grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=arch_grub
#   55  grub-mkconfig -o /boot/grub/grub.cfg
#   56  pacman -S dhcp
#   57  pacman -S openssh
#   58  vim /root/installhelp.txt
#   59  history
#
#
#before that, we needed to do pacstrap from ubuntu, and setup partitions:
#    1  cd /root
#    2  ls
#    3  lsusb
#    4  ls
#    5  lsusb
#    6  dmesg -k
#    7  lsusb
#    8  shutdown -P 0
#    9  cd /root
#   10  parted /dev/sdb
#   11  mkfs.ext4 /dev/sdb2
#   12  mkfs.fat /dev/sdb1 
#   13  mkfs.fat -F32 /dev/sdb1
#   14  ls -la /mnt
#   15  mount /dev/sdb2 /mnt
#   16  mkdir /mnt/boot
#   17  mount /dev/sdb1 /mnt/boot
#   18  apt-get install arch-install-scripts
#   19  ls
#   20  pwd
#   21  wget https://raw.githubusercontent.com/tokland/arch-bootstrap/master/arch-bootstrap.sh
#   22  wget https://raw.githubusercontent.com/tokland/arch-bootstrap/master/get-pacman-dependencies.sh
#   23  install -m 755 arch-bootstrap.sh /usr/local/bin/arch-bootstrap
#   24  arch-bootstrap /mnt
#   25  apt-get install curl
#   26  arch-bootstrap /mnt
#   27  apt-get install arch-install-scripts
#   28  chroot /mnt
#   29  mount --bind /proc /mnt/proc
#   30  mount --bind /sys /mnt/sys
#   31  mount --bind /dev /mnt/dev
#   32  mount --bind /dev/pts /mnt/dev/pts
#   33  chroot /mnt
#   34  history
#
#the partition table looks like: (without swap for usb)
#
#Disk /dev/sdc: 16,0GB
#Sector size (logical/physical): 512B/512B
#Partition Table: gpt
#Disk Flags: 
#
#Number  Start   End     Size    File system  Name   Flags
# 1      1049kB  538MB   537MB   fat32        boot   boot, esp
# 2      538MB   16,0GB  15,5GB  ext4         linux
#
