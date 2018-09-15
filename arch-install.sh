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
checkurl() {
	IFS=' ' output=( $(curl -s -m 5 -w "%{time_total} %{http_code}" "$1" -o/dev/null) )
echo "$? ${output[0]} ${output[1]}" && return
}

writemirrorfile(){
wget $1 -O $2
#myfunc里处理，这里不再需要了
#sed -i 's/#Server/Server/g' $2
awk '
function checkurl(url) {
    #cmd = "curl -s -m 5 -w \"%{http_code} %{time_total}\" " url " -o /dev/null";
    cmd = "curl -s -m 5 " url " -o /dev/null";
    return system(cmd);
}

function myfunc(line){
    resp0=match(line,/^#(Server[ \t]*=[ \t]*(http.*))$/,arr);
    if(resp0<=0)return line;
    resp1 = checkurl(arr[2]);
    if(resp1==0)return arr[1];
    return "";
}
{print myfunc($0);}' $2>$3

mv $3 $4
chmod +r $4
}

updmirror(){
color red "wget mirrorlist and update!"

writemirrorfile https://www.archlinux.org/mirrorlist/\?country=CN\&use_mirror_status=on aaa.txt aa0.txt /etc/pacman.d/mirrorlist
writemirrorfile https://raw.githubusercontent.com/archlinuxcn/mirrorlist-repo/master/archlinuxcn-mirrorlist bbb.txt bb0.txt /etc/pacman.d/archlinuxcn-mirrorlist
echo "[archlinuxcn]">>/etc/pacman.conf
echo "SigLevel = Optional TrustAll">>/etc/pacman.conf
echo "Include = /etc/pacman.d/archlinuxcn-mirrorlist">>/etc/pacman.conf
}

updtest(){
color red "wget mirrorlist and update test 1234567890!"

writemirrorfile https://www.archlinux.org/mirrorlist/\?country=CN\&use_mirror_status=on aaa.txt aa0.txt aa1.txt
writemirrorfile https://raw.githubusercontent.com/archlinuxcn/mirrorlist-repo/master/archlinuxcn-mirrorlist bbb.txt bb0.txt bb1.txt
}



beforechroot(){
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
pacstrap -i /mnt base base-devel gvim wqy-microhei fcitx-im fcitx-configtool xorg xorg-xinit xfce4 grub  google-chrome wps-office wqy-zenhei

genfstab -U /mnt > /mnt/etc/fstab

color red "cp install.sh!"
cp arch-install.sh /mnt

color red "arch-chroot!"
arch-chroot /mnt
}


afterchroot(){
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
#systemctl enable xdm.service

exit
reboot
}

domain(){
   case $1 in
        test)
            updtest
        ;;
        before)
            updmirror
            beforechroot
        ;;
       after)
            afterchroot
        ;;
       en_us)
            LANG=en_US.UTF-8
        ;;
       zh_cn)
            LANG=zh_CN.UTF-8
        ;;
    *)
        echo "before after en_us zh_cn"
        ;;
    esac
}

domain $1
