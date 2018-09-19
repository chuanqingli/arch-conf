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


write-mirror-file-awk(){
    tmpf1=$(mktemp)
    echo ${tmpf1}
    wget $1 -O ${tmpf1}
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
{print myfunc($0);}' ${tmpf1}>$2

chmod +r $2
}

