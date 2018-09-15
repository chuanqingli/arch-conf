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

color red "wget mirrorlist and update!"

wget https://www.archlinux.org/mirrorlist/\?country=CN\&use_mirror_status=on -O aaa.txt
sed -i 's/#Server/Server/g' aaa.txt
mv /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
mv aaa.txt /etc/pacman.d/mirrorlist
chmod +r /etc/pacman.d/mirrorlist

echo "[archlinuxcn]">>/etc/pacman.conf
echo "SigLevel = Optional TrustAll">>/etc/pacman.conf
echo "Server = http://mirrors.tuna.tsinghua.edu.cn/archlinuxcn/$arch">>/etc/pacman.conf

color red "cfdisk and format!"
fdisk -l
cfdisk
#fdisk /dev/sda

mkfs.ext4 /dev/sda1
mkfs.ext4 /dev/sda3

mkswap /dev/sda2
swapon /dev/sda2

color red "mount!"

mount /dev/sda1 /mnt

mkdir /mnt/home
mount /dev/sda3 /mnt/home

color red "pacstrap!"
pacstrap -i /mnt base base-devel gvim fcitx-im fcitx-configtool xorg xorg-xinit xfce4 grub lxdm  google-chrome wps-office

genfstab -U /mnt > /mnt/etc/fstab

color red "arch-chroot!"
arch-chroot /mnt

color red "zone and time update!"
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
hwclock --systohc

color red "chuanqing!"
echo chuanqing>/etc/hostname

useradd -m -g wheel chuanqing
passwd chuanqing

color red "locale!"
echo "zh_CN.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "export LANG=zh_CN.UTF-8">>/etc/locale.conf
echo "export LANGUAGE=zh_CN:en_US">>/etc/locale.conf
echo "export XMODIFIERS=@im=fcitx">>/etc/locale.conf

grub-install --recheck /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg
systemctl enable dhcpcd.service
systemctl enable lxdm.service

exit
reboot
