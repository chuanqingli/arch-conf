#!/bin/bash
mkfs-and-mount(){
<<'COMMENT'
按“分区 格式化类别 挂载点;”格式填写磁盘操作，格式化类别、挂载点不做操作的填0；
格式化类别可选ext3、ext4、swap、0；
挂载点如/、/home、/var、/tmp，不挂载填0；


COMMENT

sddata=`((a1 ext4 /)
(a3 ext4 /home)
(a2 swap 0))`


    # select mirror in "`tail -n 1 /etc/pacman.d/mirrorlist`" "`tail -n 2 /etc/pacman.d/mirrorlist | head -n 1`" "`tail -n 3 /etc/pacman.d/mirrorlist | head -n 1`";do
    #     echo $mirror > /etc/pacman.d/mirrorlist
    # break
    # done



devdata=(`df -hT|grep ^/dev/sd|awk '{print $1}'`)

#sddata=`echo ${sddata}|sed -n "s/\([ \t\n]*;[ \t\n]*\)\+/\n/gp"|sed -n "v#^\/dev\/sd#d"`

echo ${devdata[*]} ";" ${#devdata[*]} 
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

# awk 'ARGIND==1 {FS="[^0-9]+";aaa[$2]=$3} ARGIND==2 {FS="[()]+";print $2,($2 in aaa)?aaa[$2]:0}' aaa.txt bbb.txt


#awk 'ARGIND==1 {a[$1]=a[$1]"|"$2;} ARGIND==2 {print $1;}' aaa.txt bbb.txt
# awk 'ARGIND==0 {FS="[ \t]+";a[$1]=a[$1]"|"$2;}END{for(ttt in a){print ttt,"\t",a[ttt]}}' aaa.txt
awk 'ARGIND==1 {aaa[$1]=aaa[$1]"|"$2;} ARGIND==2 {print $1,"\t",($1 in aaa)?aaa[$1]:"";}' aaa.txt bbb.txt
awk 'ARGIND==1 {FS="[ \t]+";aaa[$1]=aaa[$1]"|"$2;} ARGIND==2 {print $1;}' aaa.txt bbb.txt

awk '{if(ARGIND==1){FS="[ \t]+";aaa[$1]=aaa[$1]"|"$2;} if(ARGIND==2){print $1,"\t",($1 in aaa)?aaa[$1]:"";}}' aaa.txt bbb.txt
#END{for(ttt in a){print ttt "\t" a[ttt]}}
