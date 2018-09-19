#!/bin/bash

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
extend-echo-awk(){

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

dotest(){
extend-echo red "wget mirrorlist and update!"
extend-echo Bred "wget mirrorlist and update!"
extend-echo green "wget mirrorlist and update!"
extend-echo Byellow "wget mirrorlist and update!"
extend-echo info "wget mirrorlist and update!"
extend-echo warn "wget mirrorlist and update!"
extend-echo error "wget mirrorlist and update!"
extend-echo "1;7;5;31;43" "wget mirrorlist and update!"

    
}

dotest
#echo $(echo-color-value Byellow)

