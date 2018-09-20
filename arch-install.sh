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
            extend-echo green ${BASH_REMATCH[2]} "==>" ${resp[@]}
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
    extend-echo red "wget mirrorlist and update!"

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

mkfs-and-mount(){
    <<'COMMENT'
按“分区 格式化类别 挂载点;”格式填写磁盘操作，格式化类别、挂载点不做操作的填0；
格式化类别可选ext3、ext4、swap、0；
挂载点如/、/home、/var、/tmp，不挂载填0；


COMMENT

    sddata=(
        "/dev/sda1 ext4 /"
        "/dev/sda3 ext4 /home"
        "/dev/sda2 swap 0"
    )

    devdata=`fdisk -l|grep ^/dev/sd|awk '{print $1}'`
    for i in ${!sddata[@]};do

        ppp=(${sddata[$i]})

        if [[ ${#ppp[@]} -ne 3 ]];then
            continue;
        fi

        checkok=0
        for x in ${devdata};do
            if [[ $x == ${ppp[0]} ]];then
                checkok=1
                break;
            fi
        done

        if [[ ${checkok} == 0 ]];then
            continue;
        fi

        if [[ ${ppp[1]} == swap ]];then
            mkswap ${ppp[0]}
            swapon ${ppp[0]}
            continue;
        elif [[ ${ppp[1]} != 0 ]];then
            mkfs -t ${ppp[1]} ${ppp[0]}
        fi

        if [[ ${ppp[2]} != 0 ]];then
            mpath=/mnt${ppp[2]}
            if [[ ${mpath} != "/" ]];then
                mkdir -p ${mpath}
            fi
            mount ${ppp[0]} ${mpath}
        fi
    done
}

before-chroot(){
    update-mirror-file
    
    extend-echo red "cfdisk!"
    fdisk -l
    cfdisk
    #fdisk /dev/sda

    extend-echo red "mkfs and mount!"
    mkfs-and-mount

    extend-echo red "pacstrap base system!"
    pacstrap -i /mnt base base-devel wget gvim wqy-microhei fcitx-im fcitx-configtool xorg xorg-xinit grub google-chrome wps-office wqy-zenhei ttf-wps-fonts xfce4 xfce4-goodies xfce4-terminal lightdm lightdm-gtk-greeter networkmanager network-manager-applet

    genfstab -U /mnt > /mnt/etc/fstab

    extend-echo red "cp install.sh!"
    cp arch-install.sh /mnt
    cp arch-install.sh /home

    extend-echo red "arch-chroot!"
    arch-chroot /mnt
}

write-home-conf(){
    localeconf=/home/$1/.config/locale.conf
    echo "export LANG=zh_CN.UTF-8">>${localeconf}
    echo "export LANGUAGE=zh_CN:en_US">>${localeconf}
    echo "export XMODIFIERS=@im=fcitx">>${localeconf}
}

after-chroot(){
    extend-echo red "zone and time update!"
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
    hwclock --systohc --localtime

    extend-echo red "chuanqing!"
    echo chuanqing>/etc/hostname

    useradd -m -g wheel chuanqing
    passwd chuanqing

    extend-echo red "locale!"

    sed -i 's/^#\(\(zh_CN\|en_US\)\.UTF-8 UTF-8.*\)$/\1/g' /etc/pacman.conf
    locale-gen
    write-home-conf chuanqing

    grub-install --recheck /dev/sda
    grub-mkconfig -o /boot/grub/grub.cfg
    systemctl enable dhcpcd
    systemctl enable lightdm
    systemctl enable NetworkManager
    #systemctl enable xdm.service
}

domain(){
    case $1 in
        test)
            updtest
            ;;
        mirror)
            update-mirror-file
            ;;
        before)
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
