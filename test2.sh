#!/bin/bash
mkfs-and-mount(){
<<'COMMENT'
按“分区 格式化类别 挂载点;”格式填写磁盘操作，格式化类别、挂载点不做操作的填0；
格式化类别可选ext3、ext4、swap、0；
挂载点如/、/home、/var、/tmp，不挂载填0；


COMMENT

sddata=(
"/dev/sda1       ext4 /   "
"  "
"werewr"
"/dev/sda8 ext4      /home"
"/dev/sda3 ext9      /ttt"
""
"/dev/sda7      swap 0"
    
    "你好"
    "海南"
    "大学"
)

devdata=`df -hT|grep ^/dev/sd|awk '{print $1}'`
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
    elif [[ ${ppp[1]} != 0 ]];then
        mkfs -t ${ppp[0]}
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

mkfs-and-mount
