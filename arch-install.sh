#!/bin/bash
extend-echo(){
<<'COMMENT'
0 关闭所有属性 
1 设置高亮度 
4 下划线 
5 闪烁 
7 反显 
8 消隐 
30~37 前景色 
40~47 背景色 
30:黑  black
31:红  red
32:绿  green
33:黄  yellow
34:蓝  blue
35:紫  purple
36:青 indigo   
37:白  white
COMMENT

eval $(echo $1|awk '

BEGIN{
coval["black"]=0;
coval["red"]=1;
coval["green"]=2;
coval["yellow"]=3;
coval["blue"]=4;
coval["purple"]=5;
coval["indigo"]=6;   
coval["white"]=7;
}
function colorvalue(co){
    if(co in coval)return (30+coval[co]);
    resp0=match(co,/^(B)?([a-z]+)$/,arr);
    if(resp0<=0)return 0;
    if(arr[2] in coval){
        return ((arr[1]=="")?30:40)+coval[arr[2]];
    }

    return 0;
}

function echovalue(line){
    resp0 = colorvalue(line);
    if(resp0>0)return ""+resp0;

    if("info"==line)return "35";
    if("warn"==line)return "31;5;1";
    if("error"==line)return "1;5;7;30;41";
    if(sub(/^[0-9;]+$/,line))return line;
    return "0";
}

{
printf("var1=\"%s\"",echovalue($0));
}
')

#echo "==${var1}==$1======="

echo -e "\033[${var1}m$2\033[0m"
}

checkurl() {
	IFS=' ' output=( $(curl -s -m 5 -w "%{time_total} %{http_code}" "$1" -o/dev/null) )
echo "$? ${output[0]} ${output[1]}" && return
}

write-mirror-file(){
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

update-mirror-file(){
extend-echo red "wget mirrorlist and update!"

write-mirror-file https://www.archlinux.org/mirrorlist/\?country=CN\&use_mirror_status=on aaa.txt aa0.txt /etc/pacman.d/mirrorlist
write-mirror-file https://raw.githubusercontent.com/archlinuxcn/mirrorlist-repo/master/archlinuxcn-mirrorlist bbb.txt bb0.txt /etc/pacman.d/archlinuxcn-mirrorlist
echo "[archlinuxcn]">>/etc/pacman.conf
echo "SigLevel = Optional TrustAll">>/etc/pacman.conf
echo "Include = /etc/pacman.d/archlinuxcn-mirrorlist">>/etc/pacman.conf
}

updtest(){
extend-echo info "wget mirrorlist and update test 1234567890!"
extend-echo warn "wget mirrorlist and \"update\" test 1234567890!"
extend-echo error "wget mirrorlist and update test 1234567890!"
extend-echo test "wget mirrorlist and update test 1234567890!"
extend-echo yellow "wget mirrorlist and update test 1234567890!"
extend-echo Byellow "wget mirrorlist and update test 1234567890!"
extend-echo "5;7;1;37;45" "wget mirrorlist and update test 1234567890!"

#write-mirror-file https://www.archlinux.org/mirrorlist/\?country=CN\&use_mirror_status=on aaa.txt aa0.txt aa1.txt
#write-mirror-file https://raw.githubusercontent.com/archlinuxcn/mirrorlist-repo/master/archlinuxcn-mirrorlist bbb.txt bb0.txt bb1.txt
}

mkfs-and-mount(){
<<'COMMENT'
按“分区 格式化类别 挂载点”格式填写磁盘操作，格式化类别、挂载点不做操作的填0；
格式化类别可选ext3、ext4、swap、0；
挂载点如/、/home、/var、/tmp，不挂载填0；


COMMENT

sddata='


/dev/sda1       ext4 /;
/dev/sda3 ext4      /home;
/dev/sda2      swap 0'

echo ${sddata}|sed -n "s/[ \t\n]*;[ \t\n]*/\n/gp"|awk '{printf "var0=%s==>var1=%s;var2=%s;var3=%s;\n",$0,$1,$2,$3 }'

}

before-chroot(){
extend-echo red "cfdisk and format!"
fdisk -l
cfdisk
#fdisk /dev/sda

mkfs.ext4 /dev/sda1
mkfs.ext4 /dev/sda3

mkswap /dev/sda2
swapon /dev/sda2

extend-echo red "mount!"

mount /dev/sda1 /mnt

mkdir /mnt/home
mount /dev/sda3 /mnt/home

extend-echo red "pacstrap!"
pacstrap -i /mnt base base-devel gvim wqy-microhei fcitx-im fcitx-configtool xorg xorg-xinit xfce4 grub  google-chrome wps-office wqy-zenhei

genfstab -U /mnt > /mnt/etc/fstab

extend-echo red "cp install.sh!"
cp arch-install.sh /mnt

extend-echo red "arch-chroot!"
arch-chroot /mnt
}

after-chroot(){
extend-echo red "zone and time update!"
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
hwclock --systohc

extend-echo red "chuanqing!"
echo chuanqing>/etc/hostname

useradd -m -g wheel chuanqing
passwd chuanqing

extend-echo red "locale!"
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
            update-mirror-file
            before-chroot
        ;;
       after)
            after-chroot
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
