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


# getfetchurl serverurl (e.g. getturl http://foo.com/core/os/i686)
# if $repo is in the line, then assumes core
# if $arch is in the line, then assumes $(uname -m)
# returns a fetchurl (e.g. http://foo.com/core/os/i686/core.db.tar.gz)
getfetchurl() {
    ARCH="$(uname -m)"
	strippedurl="${1%/}"
	reponame2="${2%/}"
    reponame=""

	replacedurl="${strippedurl//'$arch'/$ARCH}"
    if [[ ${strippedurl} =~ '$repo' ]];then
		replacedurl="${replacedurl//'$repo'/core}"
        reponame2="core"
	fi

    if [[ -n $reponame2 ]];then
        reponame="$reponame2"
    fi

	if [[ -z $reponame || $reponame = $replacedurl ]]; then
		echo "fail"
	else
		fetchurl="${replacedurl}/$reponame.db"
		echo "$fetchurl"
	fi
}

write-mirror-file(){
    tmpf1=$(mktemp)
    tmpf2=$(mktemp)
    extend-echo green ${tmpf1} ";" ${tmpf2}
    wget $1 -O ${tmpf1}
    echo >$2
    echo >${tmpf2}

    reponame=""
    if [[ $1 =~ archlinuxcn ]];then
        reponame='archlinuxcn'
    fi
    
    cat ${tmpf1}|while read line;do
        showline=${line}
        if [[ ${line} =~ ^[#]*(Server[ \t]*=[ \t]*(http.*))$ ]];then
            showline="#"${BASH_REMATCH[1]}
            strippedurl=${BASH_REMATCH[2]}
            replacedurl=($(getfetchurl ${strippedurl} ${reponame}))
            resp=($(checkurl ${replacedurl}))
            # showstr=${BASH_REMATCH[2]}" "${replacedurl}"==>"${resp[*]}
            showstr=${strippedurl}"==>"${resp[*]}
            extend-echo yellow "$showstr"
            # echo ${showstr}
            if [[ ${resp[0]} == 0 ]];then
                echo ${resp[1]} " " ${strippedurl}>>${tmpf2}
            fi
        fi
        echo ${showline}>>$2
    done

    cat ${tmpf2}|sort -n|sed "s@^[0-9\. \t]\+@Server = @g">>$2
    chmod +r $2
}

update-mirror-file(){
    extend-echo yellow "wget mirrorlist and update!"
    if [[ $1 == 0 ]];then
        write-mirror-file https://www.archlinux.org/mirrorlist/\?country=CN\&use_mirror_status=on /etc/pacman.d/mirrorlist
    elif [[ $1 == 1 ]];then
        write-mirror-file https://raw.githubusercontent.com/archlinuxcn/mirrorlist-repo/master/archlinuxcn-mirrorlist /etc/pacman.d/archlinuxcn-mirrorlist
        # sed -i 's/^#\(XferCommand = \/usr\/bin\/wget \)/\1/g' /etc/pacman.conf

        checkok=`grep archlinuxcn /etc/pacman.conf`
        if [[ ${checkok} =~ "archlinuxcn" ]];then
            return
        fi
        echo "[archlinuxcn]">>/etc/pacman.conf
        #echo "SigLevel = Optional TrustAll">>/etc/pacman.conf
        echo "Include = /etc/pacman.d/archlinuxcn-mirrorlist">>/etc/pacman.conf
    fi
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
declare -a mkfsary=("ext4 sda1 sda3" "swap sda2")
# 指定的挂载
declare -a mountary=("sda1 /" "sda3 /home" "0 /media/win/E")
# 需要增加的挂载
declare -a fstabary=("# /dev/sda5" "UUID=000B89830009F592 /media/win/E ntfs-3g defaults 0 0") #blkid查uuid
# 自定义的安装命令
declare -a softary=()
# 操作所指向的磁盘
declare -A diskmap=([cfdisk]="sda" [grub]="sda")
# 主机名和用户名 如连网用静态ip，需要增加nic、addr、gw、dns节点
declare -A hostmap=([host]=chuanqing [user]=chuanqing)

extend-eval(){
    if [[ $1 == cfdisk ]] || [[ $1 == grub ]] ;then
	    str=${diskmap[$1]}
        ppp=($str)

        comd0=$1
        if [[ $1 == grub ]];then
            comd0="grub-install --recheck"
        fi
	    for key in ${ppp[*]};do
            ${comd0} /dev/"${key}"
	    done
        return
    fi

    aaa=()
    case "${1}" in
        mkfs)
            aaa=("${mkfsary[@]}")
            ;;
        mount)
            aaa=("${mountary[@]}")
            ;;
        fstab)
            aaa=("${fstabary[@]}")
            ;;
        soft)
            aaa=("${softary[@]}")
            ;;
        *)
            return
            ;;
    esac

    for str in "${aaa[@]}";do
        if [[ $1 == fstab ]] || [[ $1 == soft ]] ;then
            if [[ $1 == soft ]];then
                $str
                continue
            fi
            echo "$str">>/mnt/etc/fstab
            continue
        fi

        bbb=(${str})
        bbb0=${bbb[0]}
        bbbn=${bbb[*]:1:1000}
        for bbb1 in ${bbbn[*]};do
            single-$1 "${bbb0}" "${bbb1}"
        done
    done
}

single-mount(){
    if [[ $# != 2 ]];then
        return
    fi

    if [[ ! $2 =~ ^/ ]];then
        return
    fi

    if [[ $2 != / ]];then
        mkdir -p /mnt$2
    fi

    if [[ $1 == 0 ]];then
        return
    fi
    mount /dev/$1 /mnt$2
}

single-mkfs(){
    if [[ $# != 2 ]];then
        return
    fi

    if [[ $1 == swap ]];then
        mkswap /dev/$2
        swapon /dev/$2
        return
    fi
    mkfs -t $1 /dev/$2
}

single-comd(){
    if [[ $# != 1 ]];then
        return
    fi
    $1
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

init-before(){
    extend-echo red "cfdisk!"
    extend-eval cfdisk
    extend-echo red "mkfs!"
    extend-eval mkfs
    extend-echo red "mount!"
    extend-eval mount
}

before-chroot(){
    update-mirror-file 0
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
    )
    
    pacstrap -i /mnt ${pkgs[*]}

    genfstab -U /mnt > /mnt/etc/fstab
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
    update-mirror-file 1

    extend-echo yellow "run pacman!"
    # archlinuxcn支持
    pacman -S archlinuxcn-keyring
    pkgs=(
        #谷歌 wps 字体支持
        google-chrome wps-office ttf-wps-fonts wqy-zenhei
        # # 远程
        # xrdp
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
    grub-mkconfig -o /boot/grub/grub.cfg

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
        updtest
            # extend-eval soft
            ;;
        mirror)
            update-mirror-file 0
            update-mirror-file 1
            ;;
        staticip)
            static-ip-conf
            ;;
        init)
            init-before
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
            echo "init before after homeconf install mirror staticip en_us zh_cn"
            ;;
    esac
}


    # write-mirror-file https://www.archlinux.org/mirrorlist/\?country=CN\&use_mirror_status=on aaa.txt
    # write-mirror-file https://raw.githubusercontent.com/archlinuxcn/mirrorlist-repo/master/archlinuxcn-mirrorlist bbb.txt
domain $1
# getfetchurl 'https://cdn.repo.archlinuxcn.org/$arch' archlinuxcn
# getfetchurl 'http://mirrors.xjtu.edu.cn/archlinux/$repo/os/$arch'
