#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'
arch=$(arch)

installBestTrace() {   
   [[ -d /BestTrace ]] && rm -rf /BestTrace
   mkdir /BestTrace && cd /BestTrace
   wget https://github.com/zxs008/local/releases/download/bestlinux/besttrace4linux.zip && unzip besttrace4linux.zip && chmod +x besttrace && chmod +x besttracearm

   Before_ShowMenu
}

unInstallBestTrace() {   
   rm -rf /BestTrace
   Before_ShowMenu
}

pingBestTraceIp() {   
   cd /BestTrace
   
   if [[ $arch == "x86_64" || $arch == "x64" || $arch == "amd64" ]]; then
    ./besttrace -q1 -g cn $1
   elif [[ $arch == "aarch64" || $arch == "arm64" ]]; then
    ./besttracearm -q1 -g cn $1
   fi
   
   Before_ShowMenu
}

installNextTrace() {
   rm -rf nexttrace
   checkSystemArch
   wget -O nexttrace https://github.com/zxs008/local/releases/download/nexttrace/nexttrace_${osDistribution}_${archParam} && chmod +x nexttrace
   Before_ShowMenu
}

checkSystemArch() {
    osDistribution="linux"
    arch=$(uname -m)
    if [[ $arch == "x86_64" ]]; then
    archParam="amd64"
    elif [[ $arch == "aarch64" ]]; then
    archParam="arm64"
    elif [[ $arch == "armv7l" ]] || [[ $arch == "armv7ml" ]]; then
    archParam="armv7"
    fi
}

unInstallNextTrace() {   
   rm -rf nexttrace
   Before_ShowMenu
}

pingNextTraceIp() {   
   ./nexttrace -M $1
   Before_ShowMenu
}

Before_ShowMenu(){
    echo && echo -n -e "${yellow}按回车返回主菜单: ${plain}" && read temp
    ShowMenu
}

ShowMenu(){

  echo -e "
  ${green}0.${plain} 退出脚本
  ————————————————
  ${green}1.${plain} 安装BestTrace
  ${green}2.${plain} 卸载BestTrace
  ${green}3.${plain} BestTrace ping测试

  ${green}4.${plain} 安装NextTrace
  ${green}5.${plain} 卸载NextTrace
  ${green}6.${plain} NextTrace ping测试
  ————————————————
"
  echo && read -p "请输入选择 [0-3]: " num
    case "${num}" in
        0) exit 0;;
        1) installBestTrace;;
	   2) unInstallBestTrace;;
	   3)
        read -r -p "Ip: " ipAddr
        echo -e "\n"
        pingBestTraceIp $ipAddr
        ;;
        4) installNextTrace;;
	   5) unInstallNextTrace;;
	   6)
        read -r -p "Ip: " ipAddr
        echo -e "\n"
        pingNextTraceIp $ipAddr
        ;;
        *) echo -e "${red}请输入正确的数字${plain}"
        ;;
    esac
}

if [[ 1 > 0 ]]; then
    ShowMenu
fi
