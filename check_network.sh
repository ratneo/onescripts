#!/bin/bash
# Check network to China mainland
# Author: ratneo<https://yezim.com>

RED="\033[31m"      # Error message
GREEN="\033[32m"    # Success message
YELLOW="\033[33m"   # Warning message
BLUE="\033[36m"     # Info message
PLAIN='\033[0m'

BESTTRACE_FOLDER="/usr/local/bin/"
BESTTRACE_FILE="/usr/local/bin/besttrace"

myvar=$(pwd)
TEMP_FILE='ip.test'

test_area_w=("武汉电信" "武汉联通" "武汉移动")
test_ip_w=("116.211.239.114" "113.57.53.1" "120.202.35.43")
test_area_g=("广州电信" "广州联通" "广州移动")
test_ip_g=("58.60.188.222" "210.21.196.6" "120.196.165.24")
test_area_s=("上海电信" "上海联通" "上海移动")
test_ip_s=("202.96.209.133" "210.22.97.1" "211.136.112.200")
test_area_b=("北京电信" "北京联通" "北京移动")
test_ip_b=("219.141.136.12" "202.106.50.1" "221.179.155.161")
test_area_c=("成都电信" "成都联通" "成都移动")
test_ip_c=("61.139.2.69" "119.6.6.6" "211.137.96.205")


_red() { echo -e "\033[31m\033[01m$@\033[0m"; }
_green() { echo -e "\033[32m\033[01m$@\033[0m"; }
_yellow() { echo -e "\033[33m\033[01m$@\033[0m"; }
_blue() { echo -e "\033[36m\033[01m$@\033[0m"; }

coloredEcho() {
  echo -e "${1}${@:2}${PLAIN}"
}

checkRoot() {
  result=$(id | awk '{print $1}')
  if [[ $result != "uid=0(root)" ]]; then
    coloredEcho $YELLOW " 请以root身份执行该脚本"
    exit 1
  fi
}

download_besttrace() {
    if [[ -f "$BESTTRACE_FILE" ]]; then
        coloredEcho $GREEN " 已下载安装besttrace"
    else
        wget https://cdn.ipip.net/17mon/besttrace4linux.zip
        unzip -d $BESTTRACE_FOLDER besttrace4linux.zip "besttrace"
        rm besttrace4linux.zip
        chmod +x $BESTTRACE_FILE
        alias 'besttrace=besttrace -q 1'
        echo "alias 'besttrace=besttrace -q 1'" >> /root/.bashrc
    fi
}

fscarmen_route_script(){
    cd $myvar >/dev/null 2>&1
    echo -e "---------------------回程路由--感谢fscarmen开源及PR---------------------"
    rm -f $TEMP_FILE
    IP_4=$(curl -ksL4m8 -A Mozilla https://api.ip.sb/geoip) &&
    WAN_4=$(expr "$IP_4" : '.*ip\":[ ]*\"\([^"]*\).*') &&
    ASNORG_4=$(expr "$IP_4" : '.*isp\":[ ]*\"\([^"]*\).*') &&
    ASNNUM_4=$(expr "$IP_4" : '.*asn\":[ ]*\([0-9]*\).*') &&
    _blue "IPv4 ASN: AS${ASNNUM_4} ${ASNORG_4}" >> $TEMP_FILE
    IP_6=$(curl -ksL6m8 -A Mozilla https://api.ip.sb/geoip) &> /dev/null &&
    WAN_6=$(expr "$IP_6" : '.*ip\":[ ]*\"\([^"]*\).*') &> /dev/null &&
    ASNORG_6=$(expr "$IP_6" : '.*isp\":[ ]*\"\([^"]*\).*') &> /dev/null &&
    ASNNUM_6=$(expr "$IP_6" : '.*asn\":[ ]*\([0-9]*\).*') &> /dev/null &&
    _blue "IPv6 ASN: AS${ASNNUM_6} ${ASNORG_6}" >> $TEMP_FILE
    _green "依次测试电信，联通，移动经过的地区及线路，核心程序来由: ipip.net ，请知悉!" >> $TEMP_FILE
    local test_area=("${!1}")
    local test_ip=("${!2}")
    for ((a=0;a<${#test_area[@]};a++)); do
        _yellow "${test_area[a]} ${test_ip[a]}" >> $TEMP_FILE
        "$BESTTRACE_FILE" "${test_ip[a]}" -g cn 2>/dev/null | sed "s/^[ ]//g" | sed "/^[ ]/d" | sed '/ms/!d' | sed "s#.* \([0-9.]\+ ms.*\)#\1#g" >> $TEMP_FILE
    done
    cat $TEMP_FILE
    rm -f $TEMP_FILE
}

network_script_select() {
    download_besttrace
    start_time=$(date +%s)
    
    if [[ "$1" == "w" ]]; then
        fscarmen_route_script test_area_w[@] test_ip_w[@]
    elif [[ "$1" == "g" ]]; then
        fscarmen_route_script test_area_g[@] test_ip_g[@]
    elif [[ "$1" == "s" ]]; then
        fscarmen_route_script test_area_s[@] test_ip_s[@]
    elif [[ "$1" == "b" ]]; then
        fscarmen_route_script test_area_b[@] test_ip_b[@]
    elif [[ "$1" == "c" ]]; then
        fscarmen_route_script test_area_c[@] test_ip_c[@]
    else
        echo "Invalid argument, please use 'g', 's', 'b', or 'c'."
        return 1
    fi
}


startScript(){
    clear
    echo "#############################################################"
    coloredEcho ${GREEN} " 1. 三网回程路由测试(预设武汉)(平均运行1分钟)"
    coloredEcho ${GREEN} " 2. 三网回程路由测试(预设广州)(平均运行1分钟)"
    coloredEcho ${GREEN} " 3. 三网回程路由测试(预设上海)(平均运行1分钟)"
    coloredEcho ${GREEN} " 4. 三网回程路由测试(预设北京)(平均运行1分钟)"
    coloredEcho ${GREEN} " 5. 三网回程路由测试(预设成都)(平均运行1分钟)"
    coloredEcho ${GREEN} " 6. 完整的本机IP的IP质量检测(平均运行10~20秒)"
    echo "#############################################################"
    echo ""
    while true
    do
        read -rp "请输入选项:" StartInput
        case $StartInput in
            1) network_script_select 'w' ; break ;;
            2) network_script_select 'g' ; break ;;
            3) network_script_select 's' ; break ;;
            4) network_script_select 'b' ; break ;;
            5) network_script_select 'c' ; break ;;
            6) bash <(wget -qO- --no-check-certificate https://gitlab.com/spiritysdx/za/-/raw/main/qzcheck.sh); break ;;
            *) echo "输入错误，请重新输入" ;;
        esac
    done
}

checkRoot
startScript
