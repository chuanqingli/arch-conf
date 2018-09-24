#!/bin/bash
declare -a mountary=(mount "sdb1 /" "sdb3 /home" "0 /media/win/E")
declare -a mkfsary=(mkfs "ext4 sdb1" "swap sdb2")
declare -a fstabary=(fstab "# /dev/sda5" "UUID=000B89830009F592 /media/win/E ntfs-3g defaults 0 0") #blkid查uuid
declare -a softary=()

# 操作所指向的磁盘
declare -A diskmap=([cfdisk]="sdb" [grub]="sdb")
# 主机名和用户名 如连网用静态ip，需要增加nic、addr、gw、dns节点
declare -A hostmap=([host]=chuanqing [user]=chuanqing)

extend-eval(){
    if [[ $1 == cfdisk ]];then
	    arry=(${diskmap[cfdisk]})
	    for key in ${arry[@]};do
	        cfdisk /dev/${key}
	    done
    elif [[ $1 == mkfs ]];then
        extend-eval-main "${mkfsary[@]}"
    elif [[ $1 == mount ]];then
        extend-eval-main "${mountary[@]}"
    elif [[ $1 == grub ]];then
	    arry=(${diskmap[grub]})
	    for key in ${arry[@]};do
	        echo ${key}
            grub-install --recheck /dev/${key}
	    done
    elif [[ $1 == fstab ]];then
        genfstab -U /mnt > /mnt/etc/fstab
        extend-eval-main "${fstabary[@]}"
        grub-mkconfig -o /boot/grub/grub.cfg
    elif [[ $1 == soft ]];then
        extend-eval-main "${softary[@]}"
    fi
}

extend-eval-main(){
    if(($#<=1));then
        return
    fi
    
    comd=$1
    nindex=0;
    echo $#
    for x in "$@";do
        ((nindex++))
        if(($nindex==1));then
            continue
        fi
        line=(${x[@]})
        echo ${line[*]}
        if(($comd==fstab||$comd==soft));then
            extend-eval-$1 "${line[*]}"
            continue
        fi
        
        line0=${line[0]}
        for((y=1;y<${#line[@]};y++));do
            linen=${line[y]}
            extend-eval-$1 "${line0}" "${linen}"
        done
    done
}

extend-eval-mount(){
    if(($#!=2));then
        return
    fi

    if((!$2=~^/));then
        return
    fi

    if(($2!=/));then
        mkdir -p /mnt$2
    fi

    if(($1==0));then
        return
    fi
    mount /dev/$1 /mnt$2
}

extend-eval-mkfs(){
    if(($#!=2));then
        return
    fi

    if(($1==swap));then
        mkswap /dev/$2
        swapon /dev/$2
        return
    fi
    mkfs -t $1 /dev/$2
}

extend-eval-fstab(){
    if(($#!=1));then
        return
    fi
    echo $1>>/mnt/etc/fstab
}

extend-eval-soft(){
    if(($#!=1));then
        return
    fi
    $1
}


extend-eval-main "${fstabary[@]}"

