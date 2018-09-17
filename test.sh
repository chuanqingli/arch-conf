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



devdata=(`df -hT|grep ^/dev/sd|awk '{print $1}'`)

#devdata=(`echo -e ${devdata[@]}`)
#awk -v sddata=${sddata[@]} 'BEGIN{print sddata}'

echo ${sddata[*]} ";" ${#sddata[*]} 
# for day in ${sddata[@]}  #或${days[@]}
# do
#         echo $day ";"
# done

#sddata2
for i in ${!sddata[@]}
do

    ppp=(${sddata[$i]})

    if [[ ${#ppp[@]} -ne 3 ]]; then
        continue;
    fi

    # if [[ ${ppp[0]} != ^/dev/sd*$ ]]; then
    #     continue;
    # fi

    checkok=0
    for x in ${devdata[@]}
    do
        if [[ $x == ${ppp[0]} ]]; then
            checkok=1
            break;
        fi
        
    done

    if [[ ${checkok} == 0 ]]; then
        continue;
    fi
        echo ${sddata[$i]} "==>" ${ppp[@]} ":" ${#ppp[@]} ":" ${ppp[0]}
done
#sddata=`echo ${sddata}|sed -n "s/\([ \t\n]*;[ \t\n]*\)\+/\n/gp"|sed -n "v#^\/dev\/sd#d"`

#echo ${devdata[*]} ";" ${#devdata[*]} 
return

echo ${sddata}|sed -n "s/\([ \t\n]*;[ \t\n]*\)\+/\n/gp"|awk '

function chkftype(){
if($2=="0")return 1;
if($2=="swap")return 1;
if($2=="ext4")return 1;
if($2=="ext3")return 1;
if($2=="ext2")return 1;
if($2=="msdos")return 1;
return 0;
}

function doline(){
if(NF!=3)return 0;
if(index($1,"/dev/sd")!=1)return 0;
if($3!="0"&&(index($3,"/")!=1))return 0;
if(chkftype()<=0)return 0;

dd0[$1]=$2;
dd1[$1]=$3;
return index($1,"/dev/sd");
}

{doline()}

END{for(tt in dd0){printf "%s\t%s\t%s\n",tt,dd0[tt],dd1[tt]}}
#{printf "var0=%s==>var1=%s;var2=%s;var3=%s;NF=%s;\n",$0,$1,$2,$3,NF}

'

}

mkfs-and-mount
