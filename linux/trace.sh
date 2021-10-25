#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

install() {   
   [[ -d /BestTrace ]] && rm -rf /BestTrace
   mkdir /BestTrace && cd /BestTrace
   wget https://cdn.ipip.net/17mon/besttrace4linux.zip && unzip besttrace4linux.zip && chmod +x besttrace

   Before_ShowMenu
}

unInstall() {   
   rm -rf /BestTrace
   Before_ShowMenu
}

pingIp() {   
   cd /BestTrace
   ./besttrace -q1 -g cn $1
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
  ${green}3.${plain} ping测试
  ————————————————
"
  echo && read -p "请输入选择 [0-3]: " num
    case "${num}" in
        0) exit 0;;
        1) install;;
	   2) unInstall;;
	   3)
        read -r -p "Ip: " ipAddr
        echo -e "\n"
        pingIp $ipAddr
        ;;
        *) echo -e "${red}请输入正确的数字${plain}"
        ;;
    esac
}

if [[ 1 > 0 ]]; then
    ShowMenu
fi
