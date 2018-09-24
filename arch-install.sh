#!/bin/bash

<<'COMMENT'
知识点：
1、archlinux安装脚本；
2、echo的增强输出；
3、curl、wget下载文件，输出格式化；
4、mktemp指定临时文件；
5、字符串分组及匹配；
6、数组和文本的两种遍历（index、value）；
7、sed格式化或清除指定内容；
8、grep查找内容；
9、变量的计算；
10、下标数组和关联数组；
COMMENT

echo-color-value(){
    if [[ $1 =~ ^(B)?([a-z]+)$ ]];then
        t1=30
        if [[ ${BASH_REMATCH[1]} == 'B' ]];then
	    t1=40
        fi

        ccc=(black red green yellow blue purple indigo white)
        for i in ${!ccc[@]};do
            # echo ${ccc[i]} ";" ${i}
            if [[ ${BASH_REMATCH[2]} == ${ccc[i]} ]];then
                echo $(($t1+i)) && return 0
            fi
        done
        return 1
    fi
    return 2
}

echo-value(){
    resp=`echo-color-value $1`
    if [[ $? == 0 ]];then
        echo ${resp} && return 0
    fi

    resp=0
    if [[ $1 == info ]];then
        resp=35
    elif [[ $1 == warn ]];then
        resp="31;5;1"
    elif [[ $1 == error ]];then
        resp="1;5;7;30;41"
    elif [[ $1 =~ ^[0-9\;]+$ ]];then
        resp=$1
    fi

    echo ${resp} && return 0
}

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

    var1=`echo-value $1`
    echo -e "\033[${var1}m$2\033[0m"
    # echo -e "\033[${var1}m$1=(${var1})=>$2\033[0m"
}


checkurl() {
	IFS=' ' output=( $(curl -s -m 5 -w "%{time_total} %{http_code}" "$1" -o/dev/null) )
    echo "$? ${output[0]} ${output[1]}" && return
}

write-mirror-file(){
    tmpf1=$(mktemp)
    tmpf2=$(mktemp)
    extend-echo green ${tmpf1} ";" ${tmpf2}
    wget $1 -O ${tmpf1}
    echo >$2
    echo >${tmpf2}
    cat ${tmpf1}|while read line;do
        showline=${line}
        if [[ ${line} =~ ^[#]*(Server[ \t]*=[ \t]*(http.*))$ ]];then
            resp=($(checkurl ${BASH_REMATCH[2]}))
            showstr=${BASH_REMATCH[2]}'==>'${resp[*]}
            extend-echo yellow "$showstr"
            # echo ${showstr}
            if [[ ${resp[0]} == 0 ]];then
                echo ${resp[1]} " " ${BASH_REMATCH[2]}>>${tmpf2}
            fi
            showline="#"${BASH_REMATCH[1]}
        fi
        echo ${showline}>>$2
    done

    cat ${tmpf2}|sort -n|sed "s@^[0-9\. \t]\+@Server = @g">>$2
    chmod +r $2
}


update-mirror-file(){
    extend-echo yellow "wget mirrorlist and update!"

    write-mirror-file https://www.archlinux.org/mirrorlist/\?country=CN\&use_mirror_status=on /etc/pacman.d/mirrorlist
    write-mirror-file https://raw.githubusercontent.com/archlinuxcn/mirrorlist-repo/master/archlinuxcn-mirrorlist /etc/pacman.d/archlinuxcn-mirrorlist
    # sed -i 's/^#\(XferCommand = \/usr\/bin\/wget \)/\1/g' /etc/pacman.conf

    checkok=`grep archlinuxcn /etc/pacman.conf`
    if [[ ${checkok} =~ "archlinuxcn" ]];then
        return
    fi
    echo "[archlinuxcn]">>/etc/pacman.conf
    #echo "SigLevel = Optional TrustAll">>/etc/pacman.conf
    echo "Include = /etc/pacman.d/archlinuxcn-mirrorlist">>/etc/pacman.conf

    #更新软件包列表
    pacman -Syy
}

updtest(){
    write-mirror-file https://www.archlinux.org/mirrorlist/\?country=CN\&use_mirror_status=on aaa.txt
    write-mirror-file https://raw.githubusercontent.com/archlinuxcn/mirrorlist-repo/master/archlinuxcn-mirrorlist bbb.txt
}

# company
# declare -A mkfsmap=([ext4]="md0" [swap]="sda8")
# declare -A mountmap=([md0]=/ [sda9]=/home)
# declare -A diskmap=([cfdisk]="sda" [grub]="sda")
# declare -A hostmap=([host]=chuanqing [user]=chuanqing [nic]=enp5s0 [addr]=192.168.33.47/24 [gw]=192.168.33.254 [dns]=202.100.192.68)

# family
# 要格式化的分区
declare -A mkfsmap=([ext4]="sdb1" [swap]="sdb2")
# 指定的挂载
declare -A mountmap=([sdb1]=/ [sdb3]=/home [sda5]=/media/win/E)
# 操作所指向的磁盘
declare -A diskmap=([cfdisk]="sdb" [grub]="sdb")
# 主机名和用户名 如连网用静态ip，需要增加nic、addr、gw、dns节点
declare -A hostmap=([host]=chuanqing [user]=chuanqing)
# 需要增加的挂载
declare -a fstabary=("# /dev/sda5" "UUID=000B89830009F592 /media/win/E ntfs-3g defaults 0 0") #blkid查uuid
# 自定义的安装命令
declare -a softary=()

extend-eval(){
    if [[ $1 == cfdisk ]];then
	    arry=(${diskmap[cfdisk]})
	    for key in ${arry[@]};do
	        cfdisk /dev/${key}
	    done
    elif [[ $1 == mkfs ]];then
	    for key in ${!mkfsmap[@]};do
	        fsvalue=(${mkfsmap[${key}]})
	        for vkey in ${fsvalue};do
		        if [[ ${key} == swap ]];then
		            mkswap /dev/${vkey}
		            swapon /dev/${vkey}
		        else
		            mkfs -t ${key} /dev/${vkey}
		        fi
	        done
	    done
    elif [[ $1 == mount ]];then
	    for key in ${!mountmap[@]};do
	        fsvalue=${mountmap[${key}]}
	        echo /dev/${key} /mnt${fsvalue}
	        if [[ ${fsvalue} != / ]];then
		        mkdir -p /mnt${fsvalue}
	        fi
	        mount /dev/${key} /mnt${fsvalue} 
	    done
    elif [[ $1 == grub ]];then
	    arry=(${diskmap[grub]})
	    for key in ${arry[@]};do
	        echo ${key}
            grub-install --recheck /dev/${key}
	    done
    elif [[ $1 == fstab ]];then
        genfstab -U /mnt > /mnt/etc/fstab
	    for key in ${!fstabary[@]};do
	        fsvalue=${fstabary[${key}]}
	        echo ${fsvalue}>>/mnt/etc/fstab
	    done
        grub-mkconfig -o /boot/grub/grub.cfg
    elif [[ $1 == soft ]];then
        tmpary=$2
        if [[ -z $2 ]];then
            tmpary=${sortary[@]}
        fi
	    for key in ${!tmpary[@]};do
	        fsvalue=${tmpary[${key}]}
            ${fsvalue}
	    done
    fi
}

static-ip-conf(){
    tname=${hostmap[nic]}
    conffile=/etc/netctl/${tname}
    echo>${conffile}
    echo "Interface=${tname}">>${conffile}
    echo "Connection=ethernet">>${conffile}
    echo "IP=static">>${conffile}
    echo "Address=('${hostmap[addr]}')">>${conffile}
    echo "Gateway=('${hostmap[gw]}')">>${conffile}
    echo "DNS=('${hostmap[dns]}')">>${conffile}
}

before-chroot(){
    update-mirror-file
    
    extend-echo red "cfdisk!"
    fdisk -l
    #fdisk /dev/sda

    extend-echo red "mkfs and mount!"
    extend-eval cfdisk
    extend-eval mkfs
    extend-eval mount

    extend-echo yellow "run pacstrap!"
    pkgs=(
        # 系统
	    base base-devel
        # 用于挂载ntfs分区时，增加对该分区写操作的支持(arch采用了udisks2来负责挂载分区)
        ntfs-3g
        # 下载 编辑器
        wget gvim emacs
        # 版本控制
        git subversion
        # ftp
        filezilla
        # 虚拟机
        virtualbox
        # 邮箱 火狐 文泉驿微米黑
        thunderbird firefox wqy-microhei
        # 输入法
	    fcitx-im fcitx-configtool
        # 桌面 登录器
	    xorg xorg-xinit grub xfce4 xfce4-goodies xfce4-terminal	lightdm lightdm-gtk-greeter
        # 网络管理
	    networkmanager network-manager-applet
        # 时间同步
	    openntpd
        # archlinuxcn支持
        archlinuxcn-keyring
)
    
    pacstrap -i /mnt ${pkgs[*]}

    extend-eval fstab

    extend-echo yellow "cp install.sh!"
    cp arch-install.sh /mnt
    cp arch-install.sh /home

    extend-echo red "arch-chroot!"
    arch-chroot /mnt
}

write-home-conf(){
    write-locale-conf /home/$1/.config/locale.conf
}

write-locale-conf(){
    localeconf=$1
    echo>${localeconf}
    echo "export LANG=zh_CN.UTF-8">>${localeconf}
    echo "export LANGUAGE=zh_CN:en_US">>${localeconf}
    echo "export XMODIFIERS=@im=fcitx">>${localeconf}
}



write-host-name(){
    extend-echo red "hostname==>$1!"
    echo $1>/etc/hostname
}

add-user(){
    extend-echo yellow "add user==>$1!"
    useradd -m -g wheel $1
    passwd $1
}


after-chroot(){
    extend-echo yellow "run pacman!"
    pkgs=(
        #谷歌 wps 字体支持
        google-chrome wps-office ttf-wps-fonts wqy-zenhei
        # 远程
        xrdp
    )
    pacman -S ${pkgs[*]}
    extend-echo red "zone and time update!"
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
    hwclock --systohc --localtime

    write-host-name ${hostmap[host]}
    add-user ${hostmap[user]}

    extend-echo yellow "root passwd update!"
    passwd

    extend-echo red "locale!"

    sed -i 's/^#\(\(zh_CN\|en_US\)\.UTF-8 UTF-8.*\)$/\1/g' /etc/locale.gen
    locale-gen

    write-locale-conf /etc/locale.conf

    extend-eval grub

    #网卡为空
    if [[ -z ${hostmap[nic]} ]];then
	    systemctl enable dhcpcd
    else
        #静态ip时，这里设为disable，因为和networkmanager冲突
	    systemctl disable dhcpcd
    fi
    systemctl enable lightdm
    systemctl enable NetworkManager
    systemctl enable openntpd
}

self-install(){
    tmpary=("ls -al" "echo 你好====" "ls -al /")
    extend-eval soft ${tmpary}
}

domain(){
    case $1 in
        test)
        # updtest
            extend-eval soft
            ;;
        mirror)
            update-mirror-file
            ;;
        staticip)
            static-ip-conf
            ;;
        before)
            before-chroot
            ;;
        after)
            after-chroot
            ;;
        homeconf)
            write-home-conf ${hostmap[user]}
            ;;
        install)
            self-install
            ;;
        en_us)
            LANG=en_US.UTF-8
            ;;
        zh_cn)
            LANG=zh_CN.UTF-8
            ;;
        *)
            echo "before after homeconf install mirror staticip en_us zh_cn"
            ;;
    esac
}


domain $1
