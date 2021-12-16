#!/bin/bash

#======================================================
#   System Required: CentOS 7+ / Debian 8+ / Ubuntu 16+
#   Description: Manage v2-ui
#   Author: sprov
#======================================================

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}错误: ${plain} 必须使用root用户运行此脚本！\n" && exit 1

release=$(release)

# check os
if [[ -f /etc/redhat-release ]]; then
    release="centos"
elif cat /etc/issue | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
elif cat /proc/version | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
else
    release="centos"
fi

install() {   
	if [[ x"${release}" == x"centos" ]]; then
	   yum install -y wget
	   yum install -y iproute2 iproute2-doc
	   yum install -y sudo
	else
       apt-get -y install wget
	   apt-get install -y iproute2 iproute2-doc
	   apt-get -y install sudo
	   apt-get -y install iputils-ping
	fi
	
	if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

ip_install() {   
	if [[ x"${release}" == x"centos" ]]; then
	   yum install -y iproute2 iproute2-doc
	else
       apt-get install -y iproute2 iproute2-doc
	fi
	
	if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

wget_install() {   
	if [[ x"${release}" == x"centos" ]]; then
	   yum install -y wget
	else
       apt-get -y install wget
	fi
	
	if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

sudo_install() {   
	if [[ x"${release}" == x"centos" ]]; then
	   yum install -y sudo
	else
       apt-get -y install sudo
	fi
	
	if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

ping_install() {   
	if [[ x"${release}" == x"ubuntu" ]]; then
       apt-get -y install iputils-ping
	fi
	
	if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

before_show_menu() {
    echo && echo -n -e "${yellow}按回车返回主菜单: ${plain}" && read temp
    show_menu
}

show_menu() {
  echo -e "
  ${green}0.${plain} 退出脚本
————————————————
  ${green}1.${plain} 一键更新脚本
  ${green}2.${plain} ip command
  ${green}3.${plain} wget command
  ${green}4.${plain} sudo command
  ${green}5.${plain} ping command
————————————————
 "
    echo && read -p "请输入选择 [0-14]: " num

    case "${num}" in
        0) exit 0
        ;;
		1) install
        ;;
		2) ip_install
        ;;
		3) wget_install
        ;;
		4) sudo_install
        ;;
		4) ping_install
        ;;
        *) echo -e "${red}请输入正确的数字${plain}"
        ;;
    esac
}

if [[ 1 > 0 ]]; then
    show_menu
fi
