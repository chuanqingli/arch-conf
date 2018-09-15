#!/bin/bash

color(){
    case $1 in
        red)
            echo -e "\033[31m$2\033[0m"
        ;;
        green)
            echo -e "\033[32m$2\033[0m"
        ;;
    esac
}

wget https://www.archlinux.org/mirrorlist/?country=CN&use_mirror_status=on aaa.txt
sed -i 's/#Server/Server/g' aaa.txt
mv /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
mv aaa.txt /etc/pacman.d/mirrorlist
chmod +r /etc/pacman.d/mirrorlist

fdisk -l
fdisk /dev/sda

mkfs.ext4 /dev/sda1
mkfs.ext4 /dev/sda3

mkswap /dev/sda2
swapon /dev/sda2

mount /dev/sda1 /mnt

mkdir /mnt/home
mount /dev/sda3 /mnt/home

pacstrap /mnt base base-devel --force
genfstab -U -p /mnt > /mnt/etc/fstab

arch-chroot /mnt

ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
hwclock --systohc --utc

echo chuanqing>/etc/hostname

useradd -m -g wheel chuanqing
passwd chuanqing

pacman -S fcitx-im fcitx-configtool xorg xorg-xinit xfce4 grub

grub-install --recheck /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg
systemctl enable dhcpcd.service

exit
reboot
